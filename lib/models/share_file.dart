class ShareFile {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final FileType fileType;
  final DateTime createdAt;

  ShareFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    required this.fileType,
    required this.createdAt,
  });

  String get sizeInMB => (size / (1024 * 1024)).toStringAsFixed(2);
  String get sizeInGB => (size / (1024 * 1024 * 1024)).toStringAsFixed(2);

  String get displaySize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum FileType {
  image,
  video,
  audio,
  document,
  archive,
  apk,
  other;

  static FileType fromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) return FileType.image;
    if (mimeType.startsWith('video/')) return FileType.video;
    if (mimeType.startsWith('audio/')) return FileType.audio;
    if (mimeType.contains('pdf') ||
        mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('sheet')) {
      return FileType.document;
    }
    if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('7z')) {
      return FileType.archive;
    }
    if (mimeType.contains('apk')) return FileType.apk;
    return FileType.other;
  }
}
