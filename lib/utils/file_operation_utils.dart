import 'dart:io';
import 'package:open_filex/open_filex.dart';

class FileOperationUtils {
  static Future<bool> openFile(String filePath) async {
    try {
      if (!File(filePath).existsSync()) {
        return false;
      }

      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      print('Error opening file: $e');
      return false;
    }
  }

  static Future<bool> installApk(String filePath) async {
    try {
      if (!filePath.endsWith('.apk')) {
        return false;
      }

      // Use OpenFile to open APK which should trigger install dialog
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      print('Error installing APK: $e');
      return false;
    }
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  static Future<bool> fileExists(String filePath) async {
    try {
      return File(filePath).existsSync();
    } catch (e) {
      return false;
    }
  }

  static bool isApk(String filePath) => filePath.endsWith('.apk');
  static bool isImage(String filePath) {
    final extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return extensions.any((ext) => filePath.toLowerCase().endsWith(ext));
  }

  static bool isVideo(String filePath) {
    final extensions = ['.mp4', '.mkv', '.webm', '.avi', '.mov'];
    return extensions.any((ext) => filePath.toLowerCase().endsWith(ext));
  }

  static bool isAudio(String filePath) {
    final extensions = ['.mp3', '.wav', '.aac', '.flac', '.m4a'];
    return extensions.any((ext) => filePath.toLowerCase().endsWith(ext));
  }

  static String getFileIcon(String filePath) {
    if (isApk(filePath)) return '📦';
    if (isImage(filePath)) return '🖼️';
    if (isVideo(filePath)) return '🎬';
    if (isAudio(filePath)) return '🎵';
    if (filePath.endsWith('.pdf')) return '📄';
    if (filePath.endsWith('.zip') || filePath.endsWith('.rar')) return '📦';
    return '📁';
  }
}
