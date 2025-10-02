import 'dart:convert';
import 'dart:io';

class SavedGeneratedFile {
  final int? id;
  final String spaceId;
  final String spaceName;
  final String fileName;
  final String originalFileName;
  final String fileType;
  final String mimeType;
  final int fileSizeBytes;
  final String localFilePath;
  final DateTime timestamp;
  final String? description;
  final Map<String, dynamic>? metadata;

  SavedGeneratedFile({
    this.id,
    required this.spaceId,
    required this.spaceName,
    required this.fileName,
    required this.originalFileName,
    required this.fileType,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.localFilePath,
    required this.timestamp,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'space_id': spaceId,
      'space_name': spaceName,
      'file_name': fileName,
      'original_file_name': originalFileName,
      'file_type': fileType,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'local_file_path': localFilePath,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'description': description,
      'metadata': metadata != null ? json.encode(metadata!) : null,
    };
  }

  factory SavedGeneratedFile.fromMap(Map<String, dynamic> map) {
    return SavedGeneratedFile(
      id: map['id']?.toInt(),
      spaceId: map['space_id'] ?? '',
      spaceName: map['space_name'] ?? '',
      fileName: map['file_name'] ?? '',
      originalFileName: map['original_file_name'] ?? '',
      fileType: map['file_type'] ?? '',
      mimeType: map['mime_type'] ?? '',
      fileSizeBytes: map['file_size_bytes']?.toInt() ?? 0,
      localFilePath: map['local_file_path'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      description: map['description'],
      metadata: map['metadata'] != null ? json.decode(map['metadata']) : null,
    );
  }

  SavedGeneratedFile copyWith({
    int? id,
    String? spaceId,
    String? spaceName,
    String? fileName,
    String? originalFileName,
    String? fileType,
    String? mimeType,
    int? fileSizeBytes,
    String? localFilePath,
    DateTime? timestamp,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return SavedGeneratedFile(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      spaceName: spaceName ?? this.spaceName,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      localFilePath: localFilePath ?? this.localFilePath,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  bool get fileExists {
    try {
      return File(localFilePath).existsSync();
    } catch (e) {
      return false;
    }
  }

  String get fileExtension {
    return fileName.split('.').last.toLowerCase();
  }

  bool get isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
    return imageExtensions.contains(fileExtension) ||
           mimeType.startsWith('image/');
  }

  bool get isAudio {
    final audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'm4a', 'flac'];
    return audioExtensions.contains(fileExtension) ||
           mimeType.startsWith('audio/');
  }

  bool get isVideo {
    final videoExtensions = ['mp4', 'avi', 'mov', 'webm', 'mkv', 'flv'];
    return videoExtensions.contains(fileExtension) ||
           mimeType.startsWith('video/');
  }

  bool get isDocument {
    final docExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf', 'md'];
    return docExtensions.contains(fileExtension) ||
           mimeType.startsWith('text/') ||
           mimeType.contains('pdf') ||
           mimeType.contains('document');
  }

  bool get isData {
    final dataExtensions = ['json', 'csv', 'xml', 'yml', 'yaml', 'py', 'js', 'html', 'css'];
    return dataExtensions.contains(fileExtension) ||
           mimeType.contains('json') ||
           mimeType.contains('csv') ||
           mimeType.contains('xml');
  }

  String get fileTypeIcon {
    if (isImage) return '🖼️';
    if (isAudio) return '🎵';
    if (isVideo) return '🎬';
    if (isDocument) return '📄';
    if (isData) return '📊';
    return '📁';
  }

  String get fileTypeCategory {
    if (isImage) return 'Image';
    if (isAudio) return 'Audio';
    if (isVideo) return 'Video';
    if (isDocument) return 'Document';
    if (isData) return 'Data';
    return 'File';
  }
}