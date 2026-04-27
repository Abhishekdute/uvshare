import 'package:flutter/material.dart';
import '../services/file_history_service.dart';
import '../models/transfer_history.dart';
import '../widgets/app_drawer.dart';
import '../utils/file_operation_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = FileHistoryService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<TransferHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _historyService.initialize();
    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        _history = history.reversed.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Activity Log', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(primaryColor),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 100, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          const Text('Your timeline is empty', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1F2937))),
          const Text('Sent/Received files appear here', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHistoryList(Color primary) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final record = _history[index];
        final isSend = record.type == TransferType.send;
        final fileInfo = _getFileIconDetails(record.fileName);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: fileInfo.color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(fileInfo.icon, color: fileInfo.color, size: 24),
            ),
            title: Text(record.fileName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1F2937))),
            subtitle: Text('${isSend ? "To" : "From"}: ${record.deviceName} • ${record.displaySize}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: isSend ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(isSend ? 'SENT' : 'RCVD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSend ? Colors.orange : Colors.blue)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow('Status', record.status.name.toUpperCase(), Colors.green),
                    const Divider(height: 20),
                    _buildStatRow('Speed', record.displaySpeed, Colors.black87),
                    const Divider(height: 20),
                    _buildStatRow('Date', _formatDate(record.timestamp), Colors.grey),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => FileOperationUtils.openFile(record.filePath),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('OPEN FILE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary.withOpacity(0.05),
                          foregroundColor: primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String hour = dt.hour > 12 ? (dt.hour - 12).toString() : (dt.hour == 0 ? '12' : dt.hour.toString());
    String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} • $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  _FileInfo _getFileIconDetails(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.apk')) return _FileInfo(Icons.android_rounded, Colors.green);
    if (name.endsWith('.pdf')) return _FileInfo(Icons.picture_as_pdf_rounded, Colors.red);
    if (['.jpg', '.jpeg', '.png', '.gif'].any(name.endsWith)) return _FileInfo(Icons.image_rounded, Colors.orange);
    if (['.mp4', '.mkv', '.avi'].any(name.endsWith)) return _FileInfo(Icons.movie_rounded, Colors.deepPurple);
    if (['.mp3', '.wav'].any(name.endsWith)) return _FileInfo(Icons.audiotrack_rounded, Colors.blue);
    return _FileInfo(Icons.insert_drive_file_rounded, Colors.grey);
  }

  Future<void> _confirmClearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear Logs?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This will permanently delete your transfer history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CLEAR ALL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      await _historyService.clearHistory();
      _loadHistory();
    }
  }
}

class _FileInfo {
  final IconData icon;
  final Color color;
  _FileInfo(this.icon, this.color);
}
