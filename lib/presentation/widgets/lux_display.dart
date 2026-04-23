import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/light_sensor_provider.dart';

/// Lux值显示组件
class LuxDisplay extends ConsumerWidget {
  const LuxDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorState = ref.watch(lightSensorProvider);
    final recommendation = ref.watch(exposureRecommendationProvider);

    final lux = sensorState.currentReading?.lux ?? 0;
    final scene = recommendation?.scene ?? '--';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LUX 标签
          Text(
            'LUX',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          // Lux 数值
          Text(
            lux > 0 ? _formatLux(lux) : '--',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          // 场景类型
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getSceneColor(scene).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getSceneColor(scene).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '当前场景: $scene',
              style: TextStyle(
                fontSize: 16,
                color: _getSceneColor(scene),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 传感器不可用提示
          if (!sensorState.isAvailable) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '光线传感器不可用',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLux(double lux) {
    if (lux >= 100000) {
      return '99999+';
    }
    return lux.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Color _getSceneColor(String scene) {
    switch (scene) {
      case '晴天':
        return Colors.orange;
      case '多云':
        return Colors.blueGrey;
      case '阴天':
        return Colors.grey;
      case '室内晴天':
        return Colors.amber;
      case '室内灯光':
        return Colors.yellow;
      case '黄昏':
        return Colors.deepOrange;
      case '暗光':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
