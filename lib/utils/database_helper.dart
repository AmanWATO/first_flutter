import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/history_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'BrowsingHistory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE history ('
          '_id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'url TEXT, '
          'favicon TEXT, '
          'timestamp TEXT'
          ')',
        );
      },
    );
  }

  Future<List<HistoryEntry>> getHistory() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return HistoryEntry.fromMap({
        'id': maps[i]['_id'],
        'url': maps[i]['url'],
        'favicon': maps[i]['favicon'],
        'timestamp': maps[i]['timestamp'],
      });
    });
  }

  /// Gets a paginated list of history entries
  ///
  /// [page] starts at 1 (first page)
  /// [pageSize] is the number of items per page
  /// Returns a list of HistoryEntry objects ordered by most recent first
  Future<List<HistoryEntry>> getHistoryPaginated(int page, int pageSize) async {
    final db = await database;

    // Calculate offset (skip) based on page number
    final int offset = (page - 1) * pageSize;

    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'timestamp DESC',
      limit: pageSize,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return HistoryEntry.fromMap({
        'id': maps[i]['_id'],
        'url': maps[i]['url'],
        'favicon': maps[i]['favicon'],
        'timestamp': maps[i]['timestamp'],
      });
    });
  }

  /// Adds a new entry to the browsing history
  Future<int> addToHistory(HistoryEntry entry) async {
    final db = await database;
    return await db.insert('history', {
      'url': entry.url,
      'favicon': entry.favicon,
      'timestamp': entry.timestamp,
    });
  }

  /// Deletes a specific history entry by ID
  Future<int> deleteHistoryEntry(int id) async {
    final db = await database;
    return await db.delete('history', where: '_id = ?', whereArgs: [id]);
  }

  /// Counts the total number of history entries
  Future<int> getHistoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM history');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }
}
