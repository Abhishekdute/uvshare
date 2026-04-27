import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/device.dart';

class DeviceDiscoveryService {
  static final DeviceDiscoveryService _instance = DeviceDiscoveryService._internal();
  factory DeviceDiscoveryService() => _instance;
  DeviceDiscoveryService._internal();

  String? _localIP;
  String? _deviceName;
  String? _deviceId;
  
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  
  final StreamController<List<Device>> _deviceController = StreamController.broadcast();
  Stream<List<Device>> get discoveredDevices => _deviceController.stream;
  final List<Device> _devices = [];

  Future<void> initialize() async {
    final info = NetworkInfo();
    _localIP = await info.getWifiIP();
    
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceName = androidInfo.model;
      _deviceId = androidInfo.id;
    } else {
      _deviceName = 'iOS Device';
      _deviceId = 'ios_dev';
    }
  }

  // --- UDP BROADCAST (RECEIVE MODE) ---
  
  Future<void> startAdvertising() async {
    await initialize();
    if (_localIP == null) return;

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8889);
      _socket!.broadcastEnabled = true;

      final discoveryData = jsonEncode({
        'id': _deviceId,
        'name': _deviceName,
        'ip': _localIP,
        'port': 8888,
      });

      _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _socket!.send(
          utf8.encode(discoveryData),
          InternetAddress('255.255.255.255'),
          8889,
        );
      });
      print('UDP Advertising started on 8889');
    } catch (e) {
      print('UDP Advertising error: $e');
    }
  }

  void stopAdvertising() {
    _broadcastTimer?.cancel();
    _socket?.close();
    _socket = null;
  }

  // --- UDP DISCOVERY (SEND MODE) ---

  Future<void> startDiscovery() async {
    await initialize();
    _devices.clear();
    
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8889);
      _socket!.broadcastEnabled = true;
      
      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            try {
              final data = jsonDecode(utf8.decode(datagram.data));
              if (data['id'] == _deviceId) return; // Ignore self

              final device = Device(
                id: data['id'],
                name: data['name'],
                ipAddress: data['ip'],
                port: data['port'],
                isAvailable: true,
              );

              if (!_devices.any((d) => d.id == device.id)) {
                _devices.add(device);
                _deviceController.add(List.from(_devices));
              }
            } catch (e) {
              print('Error decoding discovery packet: $e');
            }
          }
        }
      });
      print('UDP Discovery started on 8889');
    } catch (e) {
      print('UDP Discovery error: $e');
    }
  }

  void stopDiscovery() {
    _socket?.close();
    _socket = null;
  }

  String? getLocalIP() => _localIP;
  String getDeviceNameValue() => _deviceName ?? 'Device';
  String getDeviceIdValue() => _deviceId ?? 'id';
}
