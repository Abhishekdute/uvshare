import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/app_drawer.dart';
import '../services/device_discovery_service.dart';
import '../services/file_transfer_service.dart';
import '../services/file_history_service.dart';
import '../models/device.dart';
import '../models/share_file.dart' as model;
import '../models/transfer_history.dart';

class SendFileScreen extends StatefulWidget {
  const SendFileScreen({super.key});

  @override
  State<SendFileScreen> createState() => _SendFileScreenState();
}

class _SendFileScreenState extends State<SendFileScreen> with SingleTickerProviderStateMixin {
  final _deviceDiscoveryService = DeviceDiscoveryService();
  final _fileTransferService = FileTransferService();
  final _historyService = FileHistoryService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late AnimationController _radarController;
  StreamSubscription? _discoverySubscription;
  
  List<Device> _discoveredDevices = [];
  List<model.ShareFile> _selectedFiles = [];
  List<model.ShareFile> _filteredFiles = [];
  String _searchQuery = "";
  bool _isSending = false;
  Device? _selectedDevice;
  double _transferProgress = 0.0;
  String _currentFileName = '';

  final Color primaryColor = const Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _initializeHistory();
    _startDiscovery();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _discoverySubscription?.cancel();
    _deviceDiscoveryService.stopDiscovery();
    super.dispose();
  }

  Future<void> _initializeHistory() async {
    await _historyService.initialize();
  }

  void _startDiscovery() {
    _deviceDiscoveryService.startDiscovery();
    _discoverySubscription = _deviceDiscoveryService.discoveredDevices.listen((devices) {
      if (mounted) setState(() => _discoveredDevices = devices);
    });
  }

  void _updateFilteredFiles() {
    setState(() {
      _filteredFiles = _selectedFiles
          .where((file) => file.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  int get _totalSize => _selectedFiles.fold(0, (sum, file) => sum + file.size);

  Future<void> _quickPick() async {
    HapticFeedback.lightImpact();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (!_selectedFiles.any((f) => f.path == file.path)) {
              _selectedFiles.add(model.ShareFile(
                id: const Uuid().v4(),
                name: file.name,
                path: file.path!,
                size: file.size,
                mimeType: file.extension ?? 'unknown',
                fileType: model.FileType.fromMimeType(file.extension ?? ''),
                createdAt: DateTime.now(),
              ));
            }
          }
          _updateFilteredFiles();
        });
      }
    } catch (e) {
      _showSnackBar('Error picking files: $e', Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Send Center', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _openScanner,
          ),
          if (_selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() { _selectedFiles.clear(); _updateFilteredFiles(); });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDiscoveryRadar(isDark),
          if (_selectedFiles.isNotEmpty) _buildSearchHeader(isDark),
          Expanded(
            child: _selectedFiles.isEmpty 
              ? _buildPlaceholder(isDark)
              : _buildFileList(isDark),
          ),
          _buildControlPanel(isDark),
        ],
      ),
    );
  }

  Widget _buildDiscoveryRadar(bool isDark) {
    return Container(
      height: 240,
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03), 
            blurRadius: 20
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (index) => AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              double progress = (_radarController.value + index / 3) % 1;
              return Container(
                width: 220 * progress,
                height: 220 * progress,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(1 - progress), width: 1.5),
                ),
              );
            },
          )),
          Icon(Icons.sensors_rounded, color: primaryColor, size: 40),
          ..._discoveredDevices.asMap().entries.map((entry) {
            int idx = entry.key;
            Device device = entry.value;
            bool isSelected = _selectedDevice?.id == device.id;
            double distance = idx > 4 ? 100.0 : 80.0;
            
            return Position(
              angle: (idx * (360 / math.max(_discoveredDevices.length, 1))),
              distance: distance,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDevice = device);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: isSelected ? primaryColor : (isDark ? Colors.grey[800] : Colors.grey.shade100),
                      radius: 18,
                      child: Icon(Icons.person, color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey), size: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.name, 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: isSelected ? primaryColor : (isDark ? Colors.grey[300] : Colors.black87)
                      )
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined, 
          size: 80, 
          color: isDark ? Colors.grey[800] : Colors.grey.shade200
        ),
        const SizedBox(height: 16),
        Text(
          'Ready to Transmit', 
          style: TextStyle(
            color: isDark ? Colors.grey[600] : Colors.grey, 
            fontWeight: FontWeight.bold
          )
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _quickPick,
          icon: const Icon(Icons.add_rounded),
          label: const Text('SELECT FILES'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, 
            foregroundColor: Colors.white, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
          ),
        ),
      ],
    );
  }

  Widget _buildFileList(bool isDark) {
    final list = _searchQuery.isEmpty ? _selectedFiles : _filteredFiles;
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final file = list[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            child: FadeInAnimation(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white, 
                  borderRadius: BorderRadius.circular(20), 
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100)
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getFileColor(file.fileType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getFileIcon(file.fileType), color: _getFileColor(file.fileType), size: 24),
                  ),
                  title: Text(
                    file.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1F2937)
                    ), 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        file.fileType.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: _getFileColor(file.fileType),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${file.displaySize}', 
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]
                        )
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                    ), 
                    onPressed: () => setState(() { _selectedFiles.removeWhere((f) => f.id == file.id); _updateFilteredFiles(); })
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getFileIcon(model.FileType type) {
    switch (type) {
      case model.FileType.image: return Icons.image_rounded;
      case model.FileType.video: return Icons.videocam_rounded;
      case model.FileType.audio: return Icons.audiotrack_rounded;
      case model.FileType.document: return Icons.description_rounded;
      case model.FileType.archive: return Icons.inventory_2_rounded;
      case model.FileType.apk: return Icons.android_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(model.FileType type) {
    switch (type) {
      case model.FileType.image: return Colors.orange;
      case model.FileType.video: return Colors.red;
      case model.FileType.audio: return Colors.teal;
      case model.FileType.document: return Colors.blue;
      case model.FileType.archive: return Colors.amber;
      case model.FileType.apk: return Colors.green;
      default: return Colors.indigo;
    }
  }

  Widget _buildSearchHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        onChanged: (val) => setState(() { _searchQuery = val; _updateFilteredFiles(); }),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search selected...',
          hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildControlPanel(bool isDark) {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white, 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12, 
            blurRadius: 10
          )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSending) ...[
            LinearProgressIndicator(
              value: _transferProgress, 
              backgroundColor: primaryColor.withOpacity(0.1), 
              valueColor: AlwaysStoppedAnimation(primaryColor)
            ),
            const SizedBox(height: 10),
            Text(
              'Sending: $_currentFileName', 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black
              )
            ),
            const SizedBox(height: 15),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(
                    '${_selectedFiles.length} Files', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black
                    )
                  ),
                  Text(
                    _formatBytes(_totalSize), 
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)
                  ),
                ]
              ),
              ElevatedButton(
                onPressed: (_selectedDevice == null || _isSending) ? null : _startTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                child: Text(_selectedDevice == null ? 'SELECT DEVICE' : 'SEND NOW'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startTransfer() async {
    setState(() => _isSending = true);
    try {
      for (var file in _selectedFiles) {
        if (!mounted) break;
        setState(() => _currentFileName = file.name);
        await _fileTransferService.sendFile(file, _selectedDevice!, onProgress: (p, s) {
          if (mounted) setState(() => _transferProgress = p);
        });
      }
      if (mounted) {
        _showSnackBar('Transfer Complete!', Colors.green);
        setState(() { _isSending = false; _selectedFiles.clear(); _selectedDevice = null; });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.redAccent);
        setState(() => _isSending = false);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Scan QR Code')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.startsWith('uvshare:')) {
                  final parts = barcode.rawValue!.split(':');
                  if (parts.length >= 4) {
                    final ip = parts[1];
                    final port = parts[2];
                    final name = parts[3];
                    
                    setState(() {
                      _selectedDevice = Device(
                        id: 'qr-$ip',
                        name: name,
                        ipAddress: ip,
                        port: int.parse(port),
                      );
                    });
                    Navigator.pop(context);
                    _showSnackBar('Linked to $name', Colors.green);
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

class Position extends StatelessWidget {
  final double angle;
  final double distance;
  final Widget child;
  const Position({super.key, required this.angle, required this.distance, required this.child});
  @override
  Widget build(BuildContext context) {
    final rad = angle * 3.14159 / 180;
    return Transform.translate(offset: Offset(distance * math.cos(rad), distance * math.sin(rad)), child: child);
  }
}
