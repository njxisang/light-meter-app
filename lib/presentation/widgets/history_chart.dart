import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/databases/history_database.dart';
import '../../data/repositories/history_repository.dart';
import '../../domain/models/light_reading.dart';

/// 历史数据查询状态
class HistoryQueryState {
  final int selectedHours;
  final List<LightReading> readings;
  final Map<String, double> stats;
  final bool isLoading;
  final String? error;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  const HistoryQueryState({
    this.selectedHours = 24,
    this.readings = const [],
    this.stats = const {'avg': 0, 'min': 0, 'max': 0},
    this.isLoading = false,
    this.error,
    this.rangeStart,
    this.rangeEnd,
  });

  HistoryQueryState copyWith({
    int? selectedHours,
    List<LightReading>? readings,
    Map<String, double>? stats,
    bool? isLoading,
    String? error,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    return HistoryQueryState(
      selectedHours: selectedHours ?? this.selectedHours,
      readings: readings ?? this.readings,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
    );
  }
}

/// 历史数据查询 Notifier
class HistoryQueryNotifier extends StateNotifier<HistoryQueryState> {
  HistoryQueryNotifier() : super(const HistoryQueryState());

  Future<void> loadHistory(int hours) async {
    state = state.copyWith(selectedHours: hours, isLoading: true, error: null);
    try {
      final end = DateTime.now();
      final start = end.subtract(Duration(hours: hours));
      final readings = await HistoryRepository.getRecentHistory(hours, limit: 500);
      final stats = await HistoryRepository.getStats(hours);
      state = state.copyWith(
        readings: readings,
        stats: stats,
        isLoading: false,
        rangeStart: start,
        rangeEnd: end,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadHistory(state.selectedHours);
  }
}

/// 历史数据查询 Provider
final historyQueryProvider =
    StateNotifierProvider<HistoryQueryNotifier, HistoryQueryState>((ref) {
  return HistoryQueryNotifier();
});

/// 历史曲线图组件 - 支持日期范围选择和统计
class HistoryChart extends ConsumerStatefulWidget {
  const HistoryChart({super.key});

  @override
  ConsumerState<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends ConsumerState<HistoryChart> {
  int? _selectedIndex;
  Offset? _touchPosition;

  @override
  void initState() {
    super.initState();
    // 初始化加载今天的数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyQueryProvider.notifier).loadHistory(24);
    });
  }

  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(historyQueryProvider);
    final readings = queryState.readings;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              const Text(
                '历史曲线',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (readings.isNotEmpty) ...[
                const Spacer(),
                Text(
                  '${readings.length}条记录',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // 范围选择器
          _buildRangeSelector(queryState.selectedHours),

          const SizedBox(height: 12),

          // 图表区域
          SizedBox(
            height: 100,
            child: queryState.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : readings.isEmpty
                    ? const Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey)))
                    : GestureDetector(
                        onPanUpdate: (d) => _onTouch(d.localPosition, readings),
                        onPanEnd: (_) => setState(() => _selectedIndex = _touchPosition = null),
                        onTapDown: (d) => _onTouch(d.localPosition, readings),
                        onTapUp: (_) => setState(() => _selectedIndex = _touchPosition = null),
                        child: Stack(
                          children: [
                            CustomPaint(size: const Size(double.infinity, 100), painter: _ChartPainter(readings)),
                            if (_selectedIndex != null && _touchPosition != null)
                              Positioned(left: _touchPosition!.dx - 40, top: 0, child: _buildTooltip(readings[_selectedIndex!])),
                          ],
                        ),
                      ),
          ),

          // 统计信息
          if (readings.isNotEmpty && !queryState.isLoading) ...[
            const SizedBox(height: 8),
            _buildStatsRow(queryState.stats),
          ],

          // 时间范围显示
          if (queryState.rangeStart != null && queryState.rangeEnd != null) ...[
            const SizedBox(height: 4),
            Text(
              '${DateFormat('MM/dd HH:mm').format(queryState.rangeStart!)} - ${DateFormat('MM/dd HH:mm').format(queryState.rangeEnd!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRangeSelector(int selectedHours) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryRepository.rangeOptions.map((opt) {
          final hours = opt['hours'] as int;
          final label = opt['label'] as String;
          final isSelected = hours == selectedHours;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(historyQueryProvider.notifier).loadHistory(hours),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE94560) : const Color(0xFF252540),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, double> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('平均', stats['avg'] ?? 0),
        _buildStatItem('最低', stats['min'] ?? 0),
        _buildStatItem('最高', stats['max'] ?? 0),
      ],
    );
  }

  Widget _buildStatItem(String label, double value) {
    String displayValue;
    if (value >= 1000000) {
      displayValue = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      displayValue = '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      displayValue = value.round().toString();
    }
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        Text(displayValue, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        Text('Lux', style: TextStyle(color: Colors.grey[600], fontSize: 9)),
      ],
    );
  }

  void _onTouch(Offset position, List<LightReading> readings) {
    if (readings.isEmpty) return;
    final stepX = context.size!.width / readings.length.clamp(1, double.infinity);
    final index = (position.dx / stepX).round().clamp(0, readings.length - 1);
    setState(() { _selectedIndex = index; _touchPosition = position; });
  }

  Widget _buildTooltip(LightReading reading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${reading.lux.round()} Lux', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(DateFormat('HH:mm:ss').format(reading.timestamp), style: TextStyle(color: Colors.grey[400], fontSize: 9)),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<LightReading> history;
  _ChartPainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFE94560)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
        const Color(0xFFE94560).withValues(alpha: 0.3),
        const Color(0xFFE94560).withValues(alpha: 0.0),
      ]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    double maxLux = 1;
    for (final r in history) { if (r.lux > maxLux) maxLux = r.lux; }
    maxLux = maxLux.clamp(1, double.infinity);

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (history.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      final y = size.height - (history[i].lux / maxLux * size.height);
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); }
      else { path.lineTo(x, y); fillPath.lineTo(x, y); }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.history.length != history.length ||
      (history.isNotEmpty && old.history.isNotEmpty && old.history.last.lux != history.last.lux);
}