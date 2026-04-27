import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/theme_service.dart';
import '../services/file_history_service.dart';
import '../models/transfer_history.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.uvshare/storage');
  final _historyService = FileHistoryService();
  
  String _totalStorage = "0 GB";
  String _freeStorage = "0 GB";
  double _storagePercent = 0.0;
  List<TransferHistory> _recentTransfers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getStorageStats();
    await _historyService.initialize();
    _loadRecentTransfers();
  }

  void _loadRecentTransfers() {
    setState(() {
      _recentTransfers = _historyService.getHistory().take(5).toList();
    });
  }

  Future<void> _getStorageStats() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getStorageInfo');
      
      // Parse strings from Kotlin to long/int and format them
      final total = int.tryParse(result['totalBytes'] ?? '0') ?? 0;
      final free = int.tryParse(result['freeBytes'] ?? '0') ?? 0;
      final used = total - free;
      
      setState(() {
        _totalStorage = _formatBytes(total);
        _freeStorage = _formatBytes(free);
        _storagePercent = total > 0 ? (used / total) * 100 : 0.0;
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get storage stats: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(primaryColor, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStorageInsightCard(primaryColor, isDark),
                  const SizedBox(height: 30),
                  _buildSectionHeader('CORE ACTIONS', isDark),
                  const SizedBox(height: 15),
                  _buildActionGrid(context, primaryColor, isDark),
                  if (_recentTransfers.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    _buildSectionHeader('RECENT ACTIVITY', isDark),
                    const SizedBox(height: 15),
                    _buildRecentTransfersList(isDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Color color, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Text(
          'UVShare Pro', 
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1F2937), 
            fontWeight: FontWeight.w900, 
            fontSize: 18
          )
        ),
        background: Container(color: isDark ? const Color(0xFF0F172A) : Colors.white),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.sort_rounded, color: isDark ? Colors.white : Colors.black, size: 28),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        Consumer<ThemeService>(
          builder: (context, themeService, child) => IconButton(
            icon: Icon(
              themeService.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: themeService.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              themeService.toggleTheme();
            },
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : Colors.black), 
              onPressed: () {
                HapticFeedback.lightImpact();
                _showNotificationsSnackBar();
              }
            ),
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  void _showNotificationsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You have 2 new transfer alerts'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(label: 'VIEW', onPressed: () => Navigator.pushNamed(context, '/history')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.w900, 
        color: isDark ? Colors.grey[500] : Colors.grey.shade500, 
        letterSpacing: 1.2
      ),
    );
  }

  Widget _buildStorageInsightCard(Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [color, const Color(0xFFA855F7)], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : color.withOpacity(0.3), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('System Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('Free: $_freeStorage', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _storagePercent / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: $_totalStorage', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
              Text('${_storagePercent.toInt()}% Used', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, Color color, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(context, 'Send Files', 'Transmit at light speed', Icons.rocket_launch_rounded, color, '/send', isDark),
        _buildActionCard(context, 'Receive', 'Wait for incoming portal', Icons.qr_code_scanner_rounded, const Color(0xFF10B981), '/receive', isDark),
        _buildActionCard(context, 'Activity Log', 'Recent transfer history', Icons.bubble_chart_rounded, const Color(0xFFF59E0B), '/history', isDark),
        _buildActionCard(context, 'Secure Vault', 'Military-grade protection', Icons.shield_rounded, const Color(0xFF6366F1), '/vault', isDark),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, String route, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03), 
              blurRadius: 15, 
              offset: const Offset(0, 8)
            )
          ],
          border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 14, 
                    color: isDark ? Colors.white : const Color(0xFF1F2937)
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle, 
                  style: TextStyle(
                    fontSize: 10, 
                    color: isDark ? Colors.grey[400] : Colors.grey.shade500, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransfersList(bool isDark) {
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentTransfers.length,
        itemBuilder: (context, index) {
          final transfer = _recentTransfers[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (transfer.type == TransferType.send ? Colors.blue : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        transfer.type == TransferType.send ? Icons.upload_rounded : Icons.download_rounded,
                        color: transfer.type == TransferType.send ? Colors.blue : Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      transfer.fileName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${transfer.deviceName} • ${_formatBytes(transfer.fileSize)}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[600] : Colors.grey),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }
}
