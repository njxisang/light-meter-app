import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 历史数据SQLite数据库
class HistoryDatabase {
  static Database? _database;
  static const String _tableName = 'light_history';

  /// 获取数据库实例（单例）
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'light_meter_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lux REAL NOT NULL,
            timestamp INTEGER NOT NULL,
            accuracy INTEGER DEFAULT 0
          )
        ''');
        // 创建时间索引用于快速范围查询
        await db.execute('''
          CREATE INDEX idx_timestamp ON $_tableName (timestamp)
        ''');
      },
    );
  }

  /// 插入一条光照记录
  static Future<int> insert(double lux, DateTime timestamp, {int accuracy = 0}) async {
    final db = await database;
    return await db.insert(_tableName, {
      'lux': lux,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
    });
  }

  /// 批量插入记录
  static Future<void> insertBatch(List<Map<String, dynamic>> records) async {
    final db = await database;
    final batch = db.batch();
    for (final record in records) {
      batch.insert(_tableName, record);
    }
    await batch.commit(noResult: true);
  }

  /// 查询指定时间范围内的记录
  static Future<List<Map<String, dynamic>>> queryRange(
    DateTime start,
    DateTime end, {
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      _tableName,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// 获取最早一条记录的时间
  static Future<DateTime?> getFirstTimestamp() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MIN(timestamp) as min_ts FROM $_tableName');
    if (result.isNotEmpty && result.first['min_ts'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(result.first['min_ts'] as int);
    }
    return null;
  }

  /// 获取最新一条记录的时间
  static Future<DateTime?> getLastTimestamp() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(timestamp) as max_ts FROM $_tableName');
    if (result.isNotEmpty && result.first['max_ts'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(result.first['max_ts'] as int);
    }
    return null;
  }

  /// 获取记录总数
  static Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_tableName');
    return result.first['cnt'] as int;
  }

  /// 查询指定时间范围内的记录数量
  static Future<int> getCountInRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_tableName WHERE timestamp >= ? AND timestamp <= ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return result.first['cnt'] as int;
  }

  /// 获取指定时间范围内的统计数据
  static Future<Map<String, double>> getStatsInRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(lux) as avg_lux, MIN(lux) as min_lux, MAX(lux) as max_lux FROM $_tableName WHERE timestamp >= ? AND timestamp <= ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    if (result.isNotEmpty) {
      return {
        'avg': (result.first['avg_lux'] as num?)?.toDouble() ?? 0,
        'min': (result.first['min_lux'] as num?)?.toDouble() ?? 0,
        'max': (result.first['max_lux'] as num?)?.toDouble() ?? 0,
      };
    }
    return {'avg': 0, 'min': 0, 'max': 0};
  }

  /// 删除指定时间之前的记录（保留最近N天）
  static Future<int> deleteBefore(DateTime cutoff) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoff.millisecondsSinceEpoch],
    );
  }

  /// 关闭数据库
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}