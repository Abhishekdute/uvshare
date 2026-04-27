class Device {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String? deviceType;
  final bool isAvailable;

  Device({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    this.deviceType,
    this.isAvailable = true,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int? ?? 8888,
      deviceType: json['deviceType'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'deviceType': deviceType,
      'isAvailable': isAvailable,
    };
  }

  @override
  String toString() => 'Device(id: $id, name: $name, ipAddress: $ipAddress)';
}
