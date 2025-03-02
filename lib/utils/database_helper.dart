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

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }
}
