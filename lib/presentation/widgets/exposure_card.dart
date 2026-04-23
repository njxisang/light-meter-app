import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/exposure_constants.dart';
import '../providers/light_sensor_provider.dart';

/// 曝光参数卡片组件
class ExposureCard extends ConsumerWidget {
  const ExposureCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(exposureRecommendationProvider);
    final sensorState = ref.watch(lightSensorProvider);
    final selectedAperture = ref.watch(apertureProvider);

    if (recommendation == null || sensorState.currentReading == null) {
      return _buildPlaceholder();
    }

    final exposureService = ref.read(exposureServiceProvider);
    final combinations = exposureService.calculateMultipleCombinations(
      lux: sensorState.currentReading!.lux,
      mode: ref.read(shootingModeProvider),
    );

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
          // 光圈选择器
          _buildApertureSelector(context, ref, selectedAperture),
          const SizedBox(height: 16),
          // 当前选择的参数
          _buildCurrentParams(recommendation, selectedAperture),
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          // 更多组合推荐
          _buildMultipleCombinations(combinations, selectedAperture),
        ],
      ),
    );
  }

  Widget _buildApertureSelector(
      BuildContext context, WidgetRef ref, double selectedAperture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '光圈',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ExposureConstants.apertureOptions.map((aperture) {
              final isSelected = aperture == selectedAperture;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    ref.read(apertureProvider.notifier).state = aperture;
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE94560)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey[700]!),
                    ),
                    child: Text(
                      'f/${aperture}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentParams(recommendation, double selectedAperture) {
    return Row(
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
        Container(
          height: 50,
          width: 1,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildParamItem(
            '光圈',
            'f/$selectedAperture',
            Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleCombinations(
      List combinations, double selectedAperture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '更多组合推荐',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // 表头
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '光圈',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '快门',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'ISO',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: Text(
                        '质量',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey, height: 1),
              // 组合列表
              ...combinations.asMap().entries.map((entry) {
                final index = entry.key;
                final combo = entry.value;
                final isSelected = ExposureConstants.apertureOptions[index] == selectedAperture;
                return Container(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'f/${combo.aperture}',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFE94560)
                                : Colors.white70,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          combo.shutterSpeed,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          combo.iso.toString(),
                          style: TextStyle(
                            color: _getIsoColor(combo.iso),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          combo.quality,
                          style: TextStyle(
                            color: _getQualityColor(combo.quality),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case '优秀':
        return Colors.green;
      case '良好':
        return Colors.lightGreen;
      case '一般':
        return Colors.orange;
      default:
        return Colors.red;
    }
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