import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class StorageVaultScreen extends StatefulWidget {
  const StorageVaultScreen({super.key});

  @override
  State<StorageVaultScreen> createState() => _StorageVaultScreenState();
}

class _StorageVaultScreenState extends State<StorageVaultScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final String _basePath = '/storage/emulated/0/Download/UVShare';
  List<FileSystemEntity> _files = [];
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final dir = Directory(_basePath);
    if (await dir.exists()) {
      setState(() {
        _files = dir.listSync().reversed.toList();
      });
    }
  }

  Future<void> _unlockVault() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication not available on this device')),
        );
        // Fallback for demo if no biometrics available
        setState(() => _isLocked = false);
        return;
      }

      final bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access your secure vault',
        biometricOnly: false,
      );

      if (authenticated) {
        setState(() => _isLocked = false);
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Secure Vault', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLocked)
            IconButton(
              icon: const Icon(Icons.lock_reset_rounded),
              onPressed: () => setState(() => _isLocked = true),
            ),
        ],
      ),
      body: _isLocked ? _buildLockedState(primaryColor) : _buildVaultContent(primaryColor),
    );
  }

  Widget _buildLockedState(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.fingerprint_rounded, size: 80, color: primary),
          ),
          const SizedBox(height: 24),
          const Text('Vault is Locked', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          const Text('Authenticate to view secure files', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _unlockVault,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('UNLOCK VAULT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultContent(Color primary) {
    return _files.isEmpty 
      ? _buildEmptyVault()
      : GridView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            final name = file.path.split('/').last;
            return _buildVaultItem(file, name, primary);
          },
        );
  }

  Widget _buildEmptyVault() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('No Secure Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildVaultItem(FileSystemEntity file, String name, Color primary) {
    final fileInfo = _getFileDetails(name);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => OpenFilex.open(file.path),
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: fileInfo.color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(fileInfo.icon, color: fileInfo.color, size: 32),
                  ),
                  const CircleAvatar(backgroundColor: Colors.white, radius: 10, child: Icon(Icons.verified_user, size: 12, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1F2937)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fileInfo.label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _VaultFileInfo _getFileDetails(String name) {
    final lowName = name.toLowerCase();
    if (lowName.endsWith('.apk')) return _VaultFileInfo(Icons.android_rounded, Colors.green, 'APP');
    if (lowName.endsWith('.pdf')) return _VaultFileInfo(Icons.picture_as_pdf_rounded, Colors.red, 'PDF');
    if (['.jpg', '.jpeg', '.png'].any(lowName.endsWith)) return _VaultFileInfo(Icons.image_rounded, Colors.orange, 'IMAGE');
    if (['.mp4', '.mkv'].any(lowName.endsWith)) return _VaultFileInfo(Icons.movie_rounded, Colors.deepPurple, 'VIDEO');
    return _VaultFileInfo(Icons.insert_drive_file_rounded, Colors.blue, 'FILE');
  }
}

class _VaultFileInfo {
  final IconData icon;
  final Color color;
  final String label;
  _VaultFileInfo(this.icon, this.color, this.label);
}
