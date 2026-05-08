import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/light_reading.dart';
import '../providers/light_sensor_provider.dart';

/// 历史曲线图组件 - 支持触摸查看具体数值
class HistoryChart extends ConsumerStatefulWidget {
  const HistoryChart({super.key});

  @override
  ConsumerState<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends ConsumerState<HistoryChart> {
  int? _selectedIndex;
  Offset? _touchPosition;

  @override
  Widget build(BuildContext context) {
    final sensorState = ref.watch(lightSensorProvider);
    final history = sensorState.history;

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
          Row(
            children: [
              const Icon(
                Icons.show_chart,
                color: Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '历史曲线',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              if (history.isNotEmpty) ...[
                const Spacer(),
                Text(
                  '${history.length}点',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      '暂无数据',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GestureDetector(
                    onPanUpdate: (details) => _onTouch(details.localPosition, history),
                    onPanEnd: (_) => setState(() {
                      _selectedIndex = null;
                      _touchPosition = null;
                    }),
                    onTapDown: (details) => _onTouch(details.localPosition, history),
                    onTapUp: (_) => setState(() {
                      _selectedIndex = null;
                      _touchPosition = null;
                    }),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(double.infinity, 100),
                          painter: _ChartPainter(history),
                        ),
                        if (_selectedIndex != null && _touchPosition != null)
                          Positioned(
                            left: _touchPosition!.dx - 30,
                            top: 0,
                            child: _buildTooltip(history[_selectedIndex!]),
                          ),
                      ],
                    ),
                  ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '触摸曲线查看具体数值',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  void _onTouch(Offset position, List<LightReading> history) {
    if (history.isEmpty) return;
    final pointCount = history.length;
    final stepX = context.size!.width / (pointCount - 1).clamp(1, double.infinity);
    final index = (position.dx / stepX).round().clamp(0, pointCount - 1);
    setState(() {
      _selectedIndex = index;
      _touchPosition = position;
    });
  }

  Widget _buildTooltip(LightReading reading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${reading.lux.round()} Lux',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
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
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE94560).withValues(alpha: 0.3),
          const Color(0xFFE94560).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // 找到最大lux值用于归一化
    double maxLux = 1;
    for (final reading in history) {
      if (reading.lux > maxLux) maxLux = reading.lux;
    }
    maxLux = maxLux.clamp(1, double.infinity);

    final path = Path();
    final fillPath = Path();

    final pointCount = history.length;
    final stepX = size.width / (pointCount - 1).clamp(1, double.infinity);

    for (int i = 0; i < pointCount; i++) {
      final x = i * stepX;
      final lux = history[i].lux;
      final y = size.height - (lux / maxLux * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // 完成填充路径
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // 绘制网格线
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.history.length != history.length ||
        (history.isNotEmpty &&
            oldDelegate.history.isNotEmpty &&
            oldDelegate.history.last.lux != history.last.lux);
  }
}
