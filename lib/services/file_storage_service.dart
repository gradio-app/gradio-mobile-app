import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import '../models/saved_generated_file.dart';
import '../models/huggingface_space.dart';

class FileStorageService {
  static const String _savedFilesFolder = 'saved_gradio_files';
  static late Directory _appDirectory;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _appDirectory = await getApplicationDocumentsDirectory();
      final savedFilesDir = Directory(path.join(_appDirectory.path, _savedFilesFolder));

      if (!await savedFilesDir.exists()) {
        await savedFilesDir.create(recursive: true);
      }

      _initialized = true;
      print('✅ File storage service initialized at: ${savedFilesDir.path}');
    } catch (e) {
      print('❌ Error initializing file storage service: $e');
      throw Exception('Failed to initialize file storage: $e');
    }
  }

  static Future<SavedGeneratedFile?> saveFileFromData({
    required HuggingFaceSpace space,
    required String fileName,
    required String fileUrl,
    String? fileData,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    try {
      print('💾 Saving file: $fileName from: ${fileUrl.length > 50 ? '${fileUrl.substring(0, 50)}...' : fileUrl}');

      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      final fileExtension = path.extension(fileName).toLowerCase();
      final fileType = _getFileTypeFromMime(mimeType);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random();
      final hashInput = '$timestamp${random.nextInt(999999)}';
      final hash = sha256.convert(utf8.encode(hashInput)).toString().substring(0, 8);

      final cleanSpaceName = space.name
          .replaceAll(RegExp(r'[^\w\-_\.]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .toLowerCase();

      final extension = path.extension(fileName);
      final baseName = path.basenameWithoutExtension(fileName);

      final uniqueFileName = '${cleanSpaceName}_${hash}$extension';

      final spaceFolder = _getSpaceFolder(space.id);
      await spaceFolder.create(recursive: true);

      final localFilePath = path.join(spaceFolder.path, uniqueFileName);
      final file = File(localFilePath);

      Uint8List fileBytes;
      int fileSizeBytes;

      if (fileData != null) {
        print('📊 Processing base64 data directly...');
        if (fileData.startsWith('data:')) {
          final dataUrlParts = fileData.split(',');
          if (dataUrlParts.length != 2) {
            throw Exception('Invalid data URL format');
          }
          fileBytes = base64Decode(dataUrlParts[1]);
        } else {
          fileBytes = base64Decode(fileData);
        }
        fileSizeBytes = fileBytes.length;
      } else if (fileUrl.startsWith('data:')) {
        print('📊 Processing data URL...');
        final dataUrlParts = fileUrl.split(',');
        if (dataUrlParts.length != 2) {
          throw Exception('Invalid data URL format');
        }

        fileBytes = base64Decode(dataUrlParts[1]);
        fileSizeBytes = fileBytes.length;
      } else {
        print('🌐 Downloading file from URL...');
        final dio = Dio();

        final response = await dio.get(
          fileUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to download file: HTTP ${response.statusCode}');
        }

        fileBytes = Uint8List.fromList(response.data);
        fileSizeBytes = fileBytes.length;
      }

      await file.writeAsBytes(fileBytes);
      print('✅ File saved locally: ${file.path} (${_formatFileSize(fileSizeBytes)})');

      final savedFile = SavedGeneratedFile(
        spaceId: space.id,
        spaceName: space.name,
        spaceUrl: space.url,
        fileName: uniqueFileName,
        originalFileName: fileName,
        fileType: fileType,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        localFilePath: localFilePath,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        description: description,
        metadata: metadata,
      );

      return savedFile;
    } catch (e) {
      print('❌ Error saving file: $e');
      return null;
    }
  }

  static Future<SavedGeneratedFile?> saveFileFromBytes({
    required HuggingFaceSpace space,
    required String fileName,
    required Uint8List fileBytes,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    try {
      print('💾 Saving file from bytes: $fileName');

      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      final fileType = _getFileTypeFromMime(mimeType);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random();
      final hashInput = '$timestamp${random.nextInt(999999)}';
      final hash = sha256.convert(utf8.encode(hashInput)).toString().substring(0, 8);

      final cleanSpaceName = space.name
          .replaceAll(RegExp(r'[^\w\-_\.]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .toLowerCase();

      final extension = path.extension(fileName);
      final baseName = path.basenameWithoutExtension(fileName);

      final uniqueFileName = '${cleanSpaceName}_${hash}$extension';

      final spaceFolder = _getSpaceFolder(space.id);
      await spaceFolder.create(recursive: true);

      final localFilePath = path.join(spaceFolder.path, uniqueFileName);
      final file = File(localFilePath);

      await file.writeAsBytes(fileBytes);

      final savedFile = SavedGeneratedFile(
        spaceId: space.id,
        spaceName: space.name,
        spaceUrl: space.url,
        fileName: uniqueFileName,
        originalFileName: fileName,
        fileType: fileType,
        mimeType: mimeType,
        fileSizeBytes: fileBytes.length,
        localFilePath: localFilePath,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        description: description,
        metadata: metadata,
      );

      print('✅ File saved from bytes: ${file.path} (${_formatFileSize(fileBytes.length)})');
      return savedFile;
    } catch (e) {
      print('❌ Error saving file from bytes: $e');
      return null;
    }
  }

  static Future<bool> deleteFile(SavedGeneratedFile savedFile) async {
    try {
      final file = File(savedFile.localFilePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted file: ${savedFile.fileName}');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting file: $e');
      return false;
    }
  }

  static Future<int> getTotalStorageUsed() async {
    await initialize();

    try {
      final savedFilesDir = Directory(path.join(_appDirectory.path, _savedFilesFolder));
      if (!await savedFilesDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in savedFilesDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('❌ Error calculating storage usage: $e');
      return 0;
    }
  }

  static Future<int> getSpaceStorageUsed(String spaceId) async {
    await initialize();

    try {
      final spaceFolder = _getSpaceFolder(spaceId);
      if (!await spaceFolder.exists()) return 0;

      int totalSize = 0;
      await for (final entity in spaceFolder.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('❌ Error calculating space storage usage: $e');
      return 0;
    }
  }

  static Future<int> cleanupOrphanedFiles(List<String> validFilePaths) async {
    await initialize();

    try {
      final savedFilesDir = Directory(path.join(_appDirectory.path, _savedFilesFolder));
      if (!await savedFilesDir.exists()) return 0;

      int deletedCount = 0;
      await for (final entity in savedFilesDir.list(recursive: true)) {
        if (entity is File && !validFilePaths.contains(entity.path)) {
          await entity.delete();
          deletedCount++;
        }
      }

      print('🧹 Cleaned up $deletedCount orphaned files');
      return deletedCount;
    } catch (e) {
      print('❌ Error cleaning up orphaned files: $e');
      return 0;
    }
  }

  static Directory _getSpaceFolder(String spaceId) {
    final safeFolderName = spaceId.replaceAll('/', '_').replaceAll(' ', '_');
    return Directory(path.join(_appDirectory.path, _savedFilesFolder, safeFolderName));
  }

  static String _getFileTypeFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('text/') || mimeType.contains('pdf') || mimeType.contains('document')) {
      return 'document';
    }
    if (mimeType.contains('json') || mimeType.contains('csv') || mimeType.contains('xml')) {
      return 'data';
    }
    return 'file';
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static Future<String> getStorageInfo() async {
    final totalBytes = await getTotalStorageUsed();
    return 'Total storage used: ${_formatFileSize(totalBytes)}';
  }
}