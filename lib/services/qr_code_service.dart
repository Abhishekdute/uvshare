import 'dart:convert';
import '../models/device.dart';

class QRCodeService {
  static final QRCodeService _instance = QRCodeService._internal();

  factory QRCodeService() {
    return _instance;
  }

  QRCodeService._internal();

  /// Generate QR code data from device information
  String generateQRCodeData(Device device) {
    final data = {
      'id': device.id,
      'name': device.name,
      'ip': device.ipAddress,
      'port': device.port,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(data);
  }

  /// Parse QR code data back to Device
  Device? parseQRCodeData(String data) {
    try {
      final json = jsonDecode(data);
      return Device.fromJson(json);
    } catch (e) {
      print('Error parsing QR code data: $e');
      return null;
    }
  }

  /// Generate simple connection string
  String generateConnectionString(Device device) {
    return 'uvshare://${device.ipAddress}:${device.port}/${device.id}';
  }

  /// Parse connection string
  Device? parseConnectionString(String connectionString) {
    try {
      // Format: uvshare://ip:port/id
      final uri = Uri.parse(connectionString);
      return Device(
        id: uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'unknown',
        name: 'Shared Device',
        ipAddress: uri.host,
        port: uri.port,
        isAvailable: true,
      );
    } catch (e) {
      print('Error parsing connection string: $e');
      return null;
    }
  }
}
