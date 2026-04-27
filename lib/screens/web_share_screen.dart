import 'package:flutter/material.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class WebShareScreen extends StatefulWidget {
  const WebShareScreen({super.key});

  @override
  State<WebShareScreen> createState() => _WebShareScreenState();
}

class _WebShareScreenState extends State<WebShareScreen> {
  HttpServer? _server;
  String? _ipAddress;
  bool _isRunning = false;
  final int _port = 8080;

  @override
  void initState() {
    super.initState();
    _getIpAddress();
  }

  Future<void> _getIpAddress() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    setState(() {
      _ipAddress = ip;
    });
  }

  Future<void> _toggleServer() async {
    if (_isRunning) {
      await _server?.close(force: true);
      setState(() {
        _isRunning = false;
        _server = null;
      });
    } else {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
        _server!.listen(_handleRequest);
        setState(() {
          _isRunning = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start server: $e')),
          );
        }
      }
    }
  }

  void _handleRequest(HttpRequest request) async {
    try {
      if (request.uri.path == '/') {
        request.response
          ..headers.contentType = ContentType.html
          ..write(_buildHtml())
          ..close();
      } else if (request.uri.path == '/files') {
        final directory = Directory('/storage/emulated/0/Download/UVShare');
        if (await directory.exists()) {
          final files = directory.listSync().whereType<File>();
          final fileList = files.map((f) => '<li><a href="/download?name=${Uri.encodeComponent(f.path.split('/').last)}">${f.path.split('/').last}</a></li>').join();
          request.response
            ..headers.contentType = ContentType.html
            ..write('<html><body><h1>Files</h1><ul>$fileList</ul></body></html>')
            ..close();
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      } else if (request.uri.path == '/download') {
        final fileName = request.uri.queryParameters['name'];
        if (fileName != null) {
          final file = File('/storage/emulated/0/Download/UVShare/$fileName');
          if (await file.exists()) {
            request.response.headers.add(
              'Content-Disposition',
              'attachment; filename="$fileName"',
            );
            await request.response.addStream(file.openRead());
            await request.response.close();
          } else {
            request.response..statusCode = HttpStatus.notFound..close();
          }
        }
      } else {
        request.response..statusCode = HttpStatus.notFound..close();
      }
    } catch (e) {
      print('WebShare error: $e');
    }
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <title>UVShare Web Portal</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: sans-serif; text-align: center; padding: 50px; background: #f0f2f5; }
        .card { background: white; padding: 30px; border-radius: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); display: inline-block; }
        h1 { color: #6366F1; }
        .btn { background: #6366F1; color: white; padding: 15px 30px; text-decoration: none; border-radius: 10px; font-weight: bold; display: inline-block; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>UVShare Web Portal</h1>
        <p>Access files from your mobile device.</p>
        <a href="/files" class="btn">View & Download Files</a>
    </div>
</body>
</html>
''';
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6366F1);
    final url = _ipAddress != null ? 'http://$_ipAddress:$_port' : 'Loading...';

    return Scaffold(
      appBar: AppBar(title: const Text('Web Share', style: TextStyle(fontWeight: FontWeight.w900))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRunning ? Icons.podcasts_rounded : Icons.language_rounded,
                  size: 100,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _isRunning ? 'Web Server is Live' : 'Share to Web Browser',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                _isRunning 
                  ? 'Enter this URL in your PC browser:' 
                  : 'Access your files from any device on the same WiFi network.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              if (_isRunning) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: SelectableText(
                    url,
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _toggleServer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.red.shade400 : primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isRunning ? 'STOP WEB SHARE' : 'START WEB SHARE',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
