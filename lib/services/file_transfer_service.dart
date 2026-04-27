import 'dart:async';
import 'dart:io';
import '../models/share_file.dart';
import '../models/device.dart';

typedef TransferProgressCallback = void Function(
  double progress, 
  double speed, 
  String? fileName, 
  int? fileSize
);

class IncomingTransfer {
  final String fileName;
  final int fileSize;
  final String deviceIp;
  final DateTime startTime;
  int receivedBytes = 0;
  bool isReceiving = true;

  IncomingTransfer({
    required this.fileName,
    required this.fileSize,
    required this.deviceIp,
    required this.startTime,
  });

  String get savePath => '/storage/emulated/0/Download/UVShare/$fileName';
  double get progress => fileSize > 0 ? receivedBytes / fileSize : 0.0;
  double get speedMBps {
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    return elapsed > 0 ? (receivedBytes / 1024 / 1024) / elapsed : 0.0;
  }
}

class FileTransferService {
  static final FileTransferService _instance = FileTransferService._internal();
  factory FileTransferService() => _instance;
  FileTransferService._internal();

  static const int _port = 8888;
  HttpServer? _server;
  bool _isServerRunning = false;

  final _incomingTransferController = StreamController<IncomingTransfer>.broadcast();
  Stream<IncomingTransfer> get incomingTransfers => _incomingTransferController.stream;

  Future<void> startServer({TransferProgressCallback? onProgress}) async {
    if (_isServerRunning) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isServerRunning = true;
      _server!.listen((HttpRequest request) => _handleRequest(request, onProgress));
      print('Server started on port $_port');
    } catch (e) {
      print('Error starting server: $e');
    }
  }

  void _handleRequest(HttpRequest request, TransferProgressCallback? onProgress) async {
    if (request.method == 'POST' && request.uri.path == '/upload') {
      try {
        final fileName = request.headers.value('x-file-name') ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
        final fileSize = int.tryParse(request.headers.value('x-file-size') ?? '0') ?? 0;
        
        final directory = Directory('/storage/emulated/0/Download/UVShare');
        if (!await directory.exists()) await directory.create(recursive: true);
        
        final file = File('${directory.path}/$fileName');
        final sink = file.openWrite();
        
        int receivedBytes = 0;
        final startTime = DateTime.now();

        await for (var data in request) {
          sink.add(data);
          receivedBytes += data.length;
          if (fileSize > 0) {
            final progress = receivedBytes / fileSize;
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            final speed = elapsed > 0 ? (receivedBytes / 1024 / 1024) / elapsed : 0.0;
            onProgress?.call(progress, speed, fileName, fileSize);
          }
        }
        
        await sink.close();
        
        // Final 100% callback
        onProgress?.call(1.0, 0.0, fileName, fileSize);

        request.response
          ..statusCode = HttpStatus.ok
          ..write('Success')
          ..close();
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..close();
      }
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }

  Future<bool> sendFile(
    ShareFile shareFile,
    Device device, {
    void Function(double progress, double speed)? onProgress,
  }) async {
    try {
      final file = File(shareFile.path);
      final totalBytes = await file.length();
      final uri = Uri.parse('http://${device.ipAddress}:${device.port}/upload');
      
      final client = HttpClient();
      final request = await client.postUrl(uri);

      request.headers.add('x-file-name', shareFile.name);
      request.headers.add('x-file-size', totalBytes.toString());
      request.headers.contentType = ContentType.binary;

      final fileStream = file.openRead();
      int bytesSent = 0;
      final startTime = DateTime.now();

      await for (var data in fileStream) {
        request.add(data);
        bytesSent += data.length;
        final progress = bytesSent / totalBytes;
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final speed = elapsed > 0 ? (bytesSent / 1024 / 1024) / elapsed : 0.0;
        onProgress?.call(progress, speed);
      }

      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      print('Send error: $e');
      return false;
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _isServerRunning = false;
  }

  bool get isServerRunning => _isServerRunning;
}
