import '../../data/databases/history_database.dart';
import '../../domain/models/light_reading.dart';

/// 历史数据仓库 - 提供持久化历史数据查询
class HistoryRepository {
  /// 预设时间范围选项
  static const List<Map<String, dynamic>> rangeOptions = [
    {'label': '1小时', 'hours': 1},
    {'label': '6小时', 'hours': 6},
    {'label': '今天', 'hours': 24},
    {'label': '3天', 'hours': 72},
    {'label': '7天', 'hours': 168},
    {'label': '30天', 'hours': 720},
  ];

  /// 查询指定范围的历史数据
  static Future<List<LightReading>> getHistory({
    required DateTime start,
    required DateTime end,
    int? limit,
  }) async {
    final records = await HistoryDatabase.queryRange(start, end, limit: limit);
    return records.map((r) => LightReading(
      lux: r['lux'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
      accuracy: r['accuracy'] as int? ?? 0,
    )).toList();
  }

  /// 查询最近N小时的历史数据
  static Future<List<LightReading>> getRecentHistory(int hours, {int? limit}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(hours: hours));
    return getHistory(start: start, end: end, limit: limit);
  }

  /// 获取指定范围的统计数据
  static Future<Map<String, double>> getStats(int hours) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(hours: hours));
    return HistoryDatabase.getStatsInRange(start, end);
  }

  /// 获取可用时间范围（第一条到最新记录的时间跨度）
  static Future<Map<String, DateTime?>> getTimeRange() async {
    final first = await HistoryDatabase.getFirstTimestamp();
    final last = await HistoryDatabase.getLastTimestamp();
    return {'first': first, 'last': last};
  }

  /// 清理旧数据（保留最近N天）
  static Future<int> cleanupOldData(int keepDays) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    return HistoryDatabase.deleteBefore(cutoff);
  }

  /// 获取记录总数
  static Future<int> getTotalCount() async {
    return HistoryDatabase.getCount();
  }
}