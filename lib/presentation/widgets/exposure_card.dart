import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/light_sensor_provider.dart';

/// 曝光参数卡片组件
class ExposureCard extends ConsumerWidget {
  const ExposureCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(exposureRecommendationProvider);
    final sensorState = ref.watch(lightSensorProvider);

    if (recommendation == null || sensorState.currentReading == null) {
      return _buildPlaceholder();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          // 标题
          const Text(
            '推荐参数',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // ISO 和 快门速度
          Row(
            children: [
              Expanded(
                child: _buildParamItem(
                  'ISO',
                  recommendation.iso.toString(),
                  _getIsoColor(recommendation.iso),
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildParamItem(
                  '快门',
                  recommendation.shutterSpeed,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 光圈
          Row(
            children: [
              Icon(
                Icons.camera,
                color: Colors.grey[500],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '光圈: f/${recommendation.aperture} (固定)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 曝光状态
          _buildExposureIndicator(recommendation.exposureStatus),
          // 警告信息
          if (recommendation.warning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.warning!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          '等待光线传感器数据...',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildParamItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildExposureIndicator(String status) {
    IconData icon;
    String text;
    Color color;

    switch (status) {
      case 'over':
        icon = Icons.exposure_plus_1;
        text = '曝光: 稍过';
        color = Colors.orange;
        break;
      case 'under':
        icon = Icons.exposure_minus_1;
        text = '曝光: 稍欠';
        color = Colors.cyan;
        break;
      default:
        icon = Icons.exposure_zero;
        text = '曝光: 正常';
        color = Colors.green;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getIsoColor(int iso) {
    if (iso <= 100) return Colors.green;
    if (iso <= 400) return Colors.lightGreen;
    if (iso <= 800) return Colors.yellow;
    if (iso <= 1600) return Colors.orange;
    return Colors.red;
  }
}
