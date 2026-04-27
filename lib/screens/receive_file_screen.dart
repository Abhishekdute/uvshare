import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/services.dart';
import '../services/file_transfer_service.dart';
import '../services/device_discovery_service.dart';
import '../widgets/transfer_progress_widget.dart';
import '../widgets/app_drawer.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> with SingleTickerProviderStateMixin {
  final _fileTransferService = FileTransferService();
  final _discoveryService = DeviceDiscoveryService();
  final _networkInfo = NetworkInfo();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late AnimationController _pulseController;

  String? _ipAddress;
  String? _wifiName;
  
  // Transfer state
  bool _isReceiving = false;
  double _progress = 0.0;
  double _speed = 0.0;
  String _currentFileName = '';
  int _currentFileSize = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _initializePortal();
  }

  Future<void> _initializePortal() async {
    // 1. Get Network Info
    await _getNetworkDetails();
    
    // 2. Start File Server
    _startServer();
    
    // 3. Start Discovery Advertising (Make visible on Radar)
    await _discoveryService.startAdvertising();
    
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fileTransferService.stopServer();
    _discoveryService.stopAdvertising();
    super.dispose();
  }

  Future<void> _getNetworkDetails() async {
    final ip = await _networkInfo.getWifiIP();
    final wifi = await _networkInfo.getWifiName();
    if (mounted) {
      setState(() {
        _ipAddress = ip ?? '127.0.0.1';
        _wifiName = wifi?.replaceAll('"', '') ?? 'Local Network';
      });
    }
  }

  void _startServer() {
    _fileTransferService.startServer(
      onProgress: (progress, speed, fileName, fileSize) {
        if (mounted) {
          setState(() {
            _isReceiving = true;
            _progress = progress;
            _speed = speed;
            _currentFileName = fileName ?? 'Incoming File';
            _currentFileSize = fileSize ?? 0;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Receive Portal', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.grey),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Use ListView to ensure content doesn't jump due to layout changes
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 20),
              // Wrap the top part in a fixed height container to lock positions
              RepaintBoundary(
                child: Column(
                  children: [
                    _buildAnimatedRadar(primaryColor, isDark),
                    const SizedBox(height: 30),
                    _buildStatusBadge(isDark),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildNetworkStatusCard(primaryColor, isDark),
              const SizedBox(height: 24),
              _buildQRPortal(primaryColor, isDark),
              const SizedBox(height: 40),
            ],
          ),
          if (_isReceiving) Positioned.fill(child: _buildTransferOverlay(isDark)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Text('PORTAL ACTIVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildAnimatedRadar(Color color, bool isDark) {
    return SizedBox(
      height: 240, // Fixed height to prevent shifting
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (index) => AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double waveValue = (_pulseController.value + (index * 0.33)) % 1.0;
              return Container(
                width: 180 * waveValue + 40,
                height: 180 * waveValue + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(1 - waveValue), width: 1.5),
                ),
              );
            },
          )),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 45),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusCard(Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.network_wifi_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_wifiName ?? 'Scanning Network...', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF1F2937))),
                Text('IP: ${_ipAddress ?? 'Getting address...'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRPortal(Color color, bool isDark) {
    final String deviceName = _discoveryService.getDeviceNameValue();
    final String qrData = 'uvshare:$_ipAddress:8888:$deviceName';
    
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: isDark ? Colors.black45 : Colors.black.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180.0,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: color),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF1F2937)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Scan to Link', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('Tell the sender to scan this QR code', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('How to Receive?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.wifi, color: Colors.indigo), title: Text('Connect to same WiFi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
            ListTile(leading: Icon(Icons.qr_code, color: Colors.indigo), title: Text('Let sender scan your QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
            ListTile(leading: Icon(Icons.radar, color: Colors.indigo), title: Text('Stay on this screen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('UNDERSTOOD'))],
      ),
    );
  }

  Widget _buildTransferOverlay(bool isDark) {
    return Container(
      color: isDark ? Colors.black.withOpacity(0.95) : Colors.white.withOpacity(0.98),
      child: Center(
        child: TransferProgressWidget(
          fileName: _currentFileName,
          deviceName: 'Sender',
          progress: _progress,
          speedMBps: _speed,
          totalFileSize: _currentFileSize,
          isUpload: false,
        ),
      ),
    );
  }
}
