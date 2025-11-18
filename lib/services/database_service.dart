import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:beta_caller/models/call_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'beta_caller.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _callHistoryTable = 'call_history';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create call history table
    await db.execute('''
      CREATE TABLE $_callHistoryTable (
        id TEXT PRIMARY KEY,
        contact_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        call_type INTEGER NOT NULL,
        call_status INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        duration INTEGER,
        cost REAL,
        country_code TEXT,
        twilio_call_sid TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic if needed
    }
  }

  // Call History Operations
  Future<int> insertCall(CallModel call) async {
    final db = await database;
    return await db.insert(
      _callHistoryTable,
      call.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CallModel>> getCallHistory({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _callHistoryTable,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return CallModel.fromDatabase(maps[i]);
    });
  }

  Future<List<CallModel>> getCallsByPhoneNumber(String phoneNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _callHistoryTable,
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return CallModel.fromDatabase(maps[i]);
    });
  }

  Future<int> deleteCall(String callId) async {
    final db = await database;
    return await db.delete(
      _callHistoryTable,
      where: 'id = ?',
      whereArgs: [callId],
    );
  }

  Future<int> clearCallHistory() async {
    final db = await database;
    return await db.delete(_callHistoryTable);
  }

  Future<Map<String, dynamic>> getCallStatistics() async {
    final db = await database;

    final totalCalls = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_callHistoryTable'),
    );

    final totalDuration = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(duration) FROM $_callHistoryTable'),
    );

    final totalCost = await db.rawQuery(
      'SELECT SUM(cost) as total FROM $_callHistoryTable',
    );

    return {
      'total_calls': totalCalls ?? 0,
      'total_duration': totalDuration ?? 0,
      'total_cost': totalCost.isNotEmpty ? totalCost[0]['total'] ?? 0.0 : 0.0,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
