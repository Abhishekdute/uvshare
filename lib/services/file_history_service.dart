import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transfer_history.dart';

class FileHistoryService {
  static final FileHistoryService _instance = FileHistoryService._internal();
  factory FileHistoryService() => _instance;
  FileHistoryService._internal();

  static const String _historyKey = 'file_transfer_history';
  late SharedPreferences _prefs;
  List<TransferHistory> _history = [];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadHistory();
  }

  void _loadHistory() {
    final jsonList = _prefs.getStringList(_historyKey) ?? [];
    _history = jsonList
        .map((json) => TransferHistory.fromJson(jsonDecode(json)))
        .toList();
    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addTransfer(TransferHistory transfer) async {
    _history.insert(0, transfer);
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    final jsonList = _history.map((h) => jsonEncode(h.toJson())).toList();
    await _prefs.setStringList(_historyKey, jsonList);
  }

  List<TransferHistory> getHistory() => List.unmodifiable(_history);

  List<TransferHistory> getRecentTransfers(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _history.where((h) => h.timestamp.isAfter(cutoffDate)).toList();
  }

  Future<void> deleteTransfer(String id) async {
    _history.removeWhere((h) => h.id == id);
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _prefs.remove(_historyKey);
  }

  List<TransferHistory> searchHistory(String query) {
    return _history
        .where(
          (h) =>
              h.fileName.toLowerCase().contains(query.toLowerCase()) ||
              h.deviceName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
