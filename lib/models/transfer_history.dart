class TransferHistory {
  final String id;
  final String fileName;
  final int fileSize;
  final String deviceName;
  final String deviceIp;
  final TransferType type; // send or receive
  final TransferStatus status; // success, failed, pending
  final DateTime timestamp;
  final String filePath;
  final double averageSpeed; // MB/s
  final int durationSeconds;

  TransferHistory({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.deviceName,
    required this.deviceIp,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.filePath,
    required this.averageSpeed,
    required this.durationSeconds,
  });

  String get displaySize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get displayDuration {
    if (durationSeconds < 60) return '${durationSeconds}s';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String get displaySpeed => '${averageSpeed.toStringAsFixed(2)} MB/s';

  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  TransferHistory copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    String? deviceName,
    String? deviceIp,
    TransferType? type,
    TransferStatus? status,
    DateTime? timestamp,
    String? filePath,
    double? averageSpeed,
    int? durationSeconds,
  }) {
    return TransferHistory(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      deviceName: deviceName ?? this.deviceName,
      deviceIp: deviceIp ?? this.deviceIp,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      filePath: filePath ?? this.filePath,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'fileSize': fileSize,
    'deviceName': deviceName,
    'deviceIp': deviceIp,
    'type': type.toString(),
    'status': status.toString(),
    'timestamp': timestamp.toIso8601String(),
    'filePath': filePath,
    'averageSpeed': averageSpeed,
    'durationSeconds': durationSeconds,
  };

  factory TransferHistory.fromJson(Map<String, dynamic> json) {
    return TransferHistory(
      id: json['id'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      deviceName: json['deviceName'],
      deviceIp: json['deviceIp'],
      type: TransferType.values.firstWhere((e) => e.toString() == json['type']),
      status: TransferStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      filePath: json['filePath'],
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      durationSeconds: json['durationSeconds'],
    );
  }
}

enum TransferType { send, receive }

enum TransferStatus { success, failed, pending }
