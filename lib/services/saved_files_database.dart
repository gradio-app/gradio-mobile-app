import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/saved_generated_file.dart';

class SavedFilesDatabase {
  static Database? _database;
  static const String _tableName = 'saved_generated_files';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'saved_gradio_files.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            space_id TEXT NOT NULL,
            space_name TEXT NOT NULL,
            file_name TEXT NOT NULL,
            original_file_name TEXT NOT NULL,
            file_type TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            file_size_bytes INTEGER NOT NULL,
            local_file_path TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            description TEXT,
            metadata TEXT
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_space_timestamp ON $_tableName (space_id, timestamp DESC)
        ''');

        await db.execute('''
          CREATE INDEX idx_file_type ON $_tableName (file_type, timestamp DESC)
        ''');

        await db.execute('''
          CREATE INDEX idx_timestamp ON $_tableName (timestamp DESC)
        ''');
      },
    );
  }

  static Future<int> saveFile(SavedGeneratedFile file) async {
    try {
      final db = await database;
      final id = await db.insert(_tableName, file.toMap());
      print('💾 Saved file to database with ID: $id - ${file.originalFileName}');
      return id;
    } catch (e) {
      print('❌ Error saving file to database: $e');
      return -1;
    }
  }

  static Future<List<SavedGeneratedFile>> getAllFiles() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => SavedGeneratedFile.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting all files: $e');
      return [];
    }
  }

  static Future<List<SavedGeneratedFile>> getFilesForSpace(String spaceId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'space_id = ?',
        whereArgs: [spaceId],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => SavedGeneratedFile.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting files for space $spaceId: $e');
      return [];
    }
  }

  static Future<List<SavedGeneratedFile>> getFilesByType(String fileType) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'file_type = ?',
        whereArgs: [fileType],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => SavedGeneratedFile.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting files by type $fileType: $e');
      return [];
    }
  }

  static Future<List<SavedGeneratedFile>> searchFiles(String query) async {
    try {
      final db = await database;
      final searchQuery = '%$query%';
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: '''
          original_file_name LIKE ? OR
          description LIKE ? OR
          space_name LIKE ?
        ''',
        whereArgs: [searchQuery, searchQuery, searchQuery],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => SavedGeneratedFile.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error searching files: $e');
      return [];
    }
  }

  static Future<List<SavedGeneratedFile>> getFilesWithPagination({
    int offset = 0,
    int limit = 20,
    String? spaceId,
    String? fileType,
  }) async {
    try {
      final db = await database;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (spaceId != null) {
        whereClause = 'space_id = ?';
        whereArgs.add(spaceId);
      }

      if (fileType != null) {
        if (whereClause.isNotEmpty) {
          whereClause += ' AND ';
        }
        whereClause += 'file_type = ?';
        whereArgs.add(fileType);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => SavedGeneratedFile.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting files with pagination: $e');
      return [];
    }
  }

  static Future<bool> deleteFile(int id) async {
    try {
      final db = await database;
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return result > 0;
    } catch (e) {
      print('❌ Error deleting file from database: $e');
      return false;
    }
  }

  static Future<int> deleteFilesForSpace(String spaceId) async {
    try {
      final db = await database;
      final result = await db.delete(
        _tableName,
        where: 'space_id = ?',
        whereArgs: [spaceId],
      );
      print('🗑️ Deleted $result files for space: $spaceId');
      return result;
    } catch (e) {
      print('❌ Error deleting files for space: $e');
      return 0;
    }
  }

  static Future<bool> clearAllFiles() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      print('🗑️ Cleared all saved files from database');
      return true;
    } catch (e) {
      print('❌ Error clearing all files: $e');
      return false;
    }
  }

  static Future<int> getFilesCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return result.first['count'] as int;
    } catch (e) {
      print('❌ Error getting files count: $e');
      return 0;
    }
  }

  static Future<Map<String, int>> getFileCountsByType() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT file_type, COUNT(*) as count
        FROM $_tableName
        GROUP BY file_type
      ''');

      final Map<String, int> counts = {};
      for (final row in result) {
        counts[row['file_type'] as String] = row['count'] as int;
      }
      return counts;
    } catch (e) {
      print('❌ Error getting file counts by type: $e');
      return {};
    }
  }

  static Future<int> getTotalStorageUsed() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(file_size_bytes) as total FROM $_tableName');
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      print('❌ Error getting total storage used: $e');
      return 0;
    }
  }

  static Future<Map<String, int>> getStorageBySpace() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT space_id, SUM(file_size_bytes) as total
        FROM $_tableName
        GROUP BY space_id
      ''');

      final Map<String, int> storage = {};
      for (final row in result) {
        storage[row['space_id'] as String] = row['total'] as int;
      }
      return storage;
    } catch (e) {
      print('❌ Error getting storage by space: $e');
      return {};
    }
  }

  static Future<List<String>> getAllFilePaths() async {
    try {
      final db = await database;
      final result = await db.query(_tableName, columns: ['local_file_path']);
      return result.map((row) => row['local_file_path'] as String).toList();
    } catch (e) {
      print('❌ Error getting all file paths: $e');
      return [];
    }
  }

  static Future<bool> updateFileDescription(int id, String description) async {
    try {
      final db = await database;
      final result = await db.update(
        _tableName,
        {'description': description},
        where: 'id = ?',
        whereArgs: [id],
      );
      return result > 0;
    } catch (e) {
      print('❌ Error updating file description: $e');
      return false;
    }
  }

  static Future<List<SavedGeneratedFile>> getRecentFiles({int days = 7}) async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'timestamp > ?',
        whereArgs: [cutoffTime],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => SavedGeneratedFile.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting recent files: $e');
      return [];
    }
  }
}