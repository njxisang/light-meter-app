import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/exposure_constants.dart';
import '../../core/utils/exposure_calculator.dart';
import '../providers/light_sensor_provider.dart';

/// 画质质量等级
enum ImageQuality {
  optimal,   // 最优
  excellent,  // 优秀
  good,       // 良好
  fair,       // 一般
  noisy,      // 噪点较多
  veryNoisy,  // 严重噪点
}

extension ImageQualityExtension on ImageQuality {
  String get label {
    switch (this) {
      case ImageQuality.optimal:
        return '最优';
      case ImageQuality.excellent:
        return '优秀';
      case ImageQuality.good:
        return '良好';
      case ImageQuality.fair:
        return '一般';
      case ImageQuality.noisy:
        return '噪点较多';
      case ImageQuality.veryNoisy:
        return '严重噪点';
    }
  }

  String get description {
    switch (this) {
      case ImageQuality.optimal:
        return '画质最佳，细节丰富，色彩纯净';
      case ImageQuality.excellent:
        return '画质优秀，轻微噪点但可接受';
      case ImageQuality.good:
        return '画质良好，噪点不易察觉';
      case ImageQuality.fair:
        return '画质一般，噪点可见但可接受';
      case ImageQuality.noisy:
        return '噪点明显，影响细节表现';
      case ImageQuality.veryNoisy:
        return '噪点严重，画质明显下降';
    }
  }

  Color get color {
    switch (this) {
      case ImageQuality.optimal:
        return const Color(0xFF00E676);
      case ImageQuality.excellent:
        return Colors.green;
      case ImageQuality.good:
        return Colors.lightGreen;
      case ImageQuality.fair:
        return Colors.yellow;
      case ImageQuality.noisy:
        return Colors.orange;
      case ImageQuality.veryNoisy:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ImageQuality.optimal:
        return Icons.stars;
      case ImageQuality.excellent:
        return Icons.check_circle;
      case ImageQuality.good:
        return Icons.thumb_up;
      case ImageQuality.fair:
        return Icons.warning;
      case ImageQuality.noisy:
        return Icons.noise_aware;
      case ImageQuality.veryNoisy:
        return Icons.noise_control_off;
    }
  }

  static ImageQuality fromIso(int iso) {
    if (iso <= 100) return ImageQuality.optimal;
    if (iso <= 200) return ImageQuality.excellent;
    if (iso <= 400) return ImageQuality.good;
    if (iso <= 800) return ImageQuality.fair;
    if (iso <= 1600) return ImageQuality.noisy;
    return ImageQuality.veryNoisy;
  }
}

/// 曝光参数卡片组件 - 支持三个参数联动调节
class ExposureCard extends ConsumerWidget {
  const ExposureCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorState = ref.watch(lightSensorProvider);
    final mode = ref.watch(shootingModeProvider);
    final selectedAperture = ref.watch(apertureProvider);
    final selectedIso = ref.watch(selectedIsoProvider);
    final selectedShutter = ref.watch(selectedShutterProvider);

    if (sensorState.currentReading == null) {
      return _buildPlaceholder();
    }

    final lux = sensorState.currentReading!.lux;
    final ev = ExposureCalculator.calculateEV(lux);
    final targetEv = ExposureCalculator.applyModeAdjustment(ev, mode);

    // 更新当前EV到provider
    Future.microtask(() {
      if (ref.exists(exposureEvProvider)) {
        ref.read(exposureEvProvider.notifier).state = targetEv;
      }
    });

    // 计算最优ISO（基于当前选择的光圈和快门）
    final optimalIso = _calculateIso(targetEv, selectedAperture, selectedShutter);
    // 计算最优快门（基于当前选择的光圈和ISO）
    final optimalShutter = _calculateShutter(targetEv, selectedAperture, selectedIso);

    // 计算当前设置的画质等级
    final currentQuality = ImageQualityExtension.fromIso(selectedIso);

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
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '曝光参数',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'EV ${targetEv.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Color(0xFFE94560),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 最优按钮
                  GestureDetector(
                    onTap: () => _setOptimalParams(ref, targetEv),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '最优',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 三个参数选择器
          _buildParamSelectors(context, ref, selectedAperture, selectedIso, selectedShutter, optimalIso, optimalShutter),

          const SizedBox(height: 16),

          // 画质等级指示
          _buildQualityIndicator(currentQuality, selectedIso),

          const SizedBox(height: 16),

          // 曝光状态指示
          _buildExposureIndicator(targetEv, ev),

          const SizedBox(height: 20),

          // 曝光三角说明
          _buildExposureTriangleInfo(),
        ],
      ),
    );
  }

  void _setOptimalParams(WidgetRef ref, double targetEv) {
    // 最优参数：使用最大光圈(f/1.8)，最低ISO，计算对应快门
    const optimalAperture = 1.8;
    final optimalIso = ExposureConstants.minIso;  // 最低ISO
    final optimalShutter = _calculateShutter(targetEv, optimalAperture, optimalIso);

    ref.read(apertureProvider.notifier).state = optimalAperture;
    ref.read(selectedIsoProvider.notifier).state = optimalIso;
    ref.read(selectedShutterProvider.notifier).state = optimalShutter;
    ref.read(exposureEvProvider.notifier).state = targetEv;
  }

  Widget _buildParamSelectors(
    BuildContext context,
    WidgetRef ref,
    double selectedAperture,
    int selectedIso,
    double selectedShutter,
    int optimalIso,
    double optimalShutter,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 光圈选择
          _buildApertureSelector(ref, selectedAperture),

          const SizedBox(height: 12),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 12),

          // ISO选择
          _buildIsoSelector(ref, selectedIso),

          const SizedBox(height: 12),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 12),

          // 快门速度选择
          _buildShutterSelector(ref, selectedShutter),
        ],
      ),
    );
  }

  Widget _buildApertureSelector(WidgetRef ref, double selectedAperture) {
    return Row(
      children: [
        const Icon(Icons.camera, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        const SizedBox(
          width: 70,
          child: Text(
            '光圈',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ExposureConstants.apertureOptions.map((aperture) {
                final isSelected = aperture == selectedAperture;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(apertureProvider.notifier).state = aperture;
                      // 联动调整快门以保持曝光
                      final ev = ref.read(exposureEvProvider);
                      final iso = ref.read(selectedIsoProvider);
                      final newShutter = _calculateShutter(ev, aperture, iso);
                      ref.read(selectedShutterProvider.notifier).state = newShutter;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE94560) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? null : Border.all(color: Colors.grey[700]!),
                      ),
                      child: Text(
                        'f/$aperture',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIsoSelector(WidgetRef ref, int selectedIso) {
    final isoOptions = [50, 64, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800, 1000, 1250, 1600, 2000, 2500, 3200];

    return Row(
      children: [
        const Icon(Icons.iso, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        const SizedBox(
          width: 70,
          child: Text(
            'ISO',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: isoOptions.map((iso) {
                final isSelected = iso == selectedIso;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedIsoProvider.notifier).state = iso;
                      // 联动调整快门以保持曝光
                      final ev = ref.read(exposureEvProvider);
                      final aperture = ref.read(apertureProvider);
                      final newShutter = _calculateShutter(ev, aperture, iso);
                      ref.read(selectedShutterProvider.notifier).state = newShutter;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE94560) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? null : Border.all(color: Colors.grey[700]!),
                      ),
                      child: Text(
                        iso.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShutterSelector(WidgetRef ref, double selectedShutter) {
    final shutters = [1/8000.0, 1/4000.0, 1/2000.0, 1/1000.0, 1/500.0, 1/250.0, 1/125.0, 1/60.0, 1/30.0, 1/15.0, 1/8.0, 1/4.0, 1/2.0, 1.0];

    return Row(
      children: [
        const Icon(Icons.shutter_speed, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        const SizedBox(
          width: 70,
          child: Text(
            '快门',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: shutters.map((shutter) {
                final isSelected = (shutter - selectedShutter).abs() < 0.0001;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedShutterProvider.notifier).state = shutter;
                      // 联动调整ISO以保持曝光
                      final ev = ref.read(exposureEvProvider);
                      final aperture = ref.read(apertureProvider);
                      final newIso = _calculateIso(ev, aperture, shutter);
                      ref.read(selectedIsoProvider.notifier).state = newIso;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE94560) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? null : Border.all(color: Colors.grey[700]!),
                      ),
                      child: Text(
                        _shutterToString(shutter),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityIndicator(ImageQuality quality, int iso) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: quality.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: quality.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(quality.icon, color: quality.color, size: 22),
              const SizedBox(width: 8),
              Text(
                '画质等级: ${quality.label}',
                style: TextStyle(
                  color: quality.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: quality.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ISO $iso',
                  style: TextStyle(
                    color: quality.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quality.description,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 10),
          // 画质进度条
          _buildQualityBar(quality, iso),
        ],
      ),
    );
  }

  Widget _buildQualityBar(ImageQuality quality, int iso) {
    // 计算在最优到最差之间的位置 (0.0 - 1.0)
    double position = _getQualityPosition(iso);
    const double barWidth = 260;
    const double indicatorOffset = 6;

    return Column(
      children: [
        SizedBox(
          height: 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 背景条
              Container(
                height: 8,
                width: barWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00E676),
                      Colors.green,
                      Colors.lightGreen,
                      Colors.yellow,
                      Colors.orange,
                      Colors.red,
                    ],
                  ),
                ),
              ),
              // 当前位置指示器
              Positioned(
                left: position * (barWidth - indicatorOffset * 2),
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: quality.color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('最优', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            Text('一般', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            Text('噪点', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildExposureIndicator(double targetEv, double actualEv) {
    final diff = targetEv - actualEv;
    final absDiff = diff.abs();

    String status;
    Color color;
    IconData icon;

    if (absDiff < 0.5) {
      status = '曝光正常';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (diff > 0) {
      status = '稍过曝 ${diff.toStringAsFixed(1)} EV';
      color = Colors.orange;
      icon = Icons.exposure_plus_1;
    } else {
      status = '稍欠曝 ${absDiff.toStringAsFixed(1)} EV';
      color = Colors.cyan;
      icon = Icons.exposure_minus_1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            '调整任一参数，其他联动变化',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildExposureTriangleInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '曝光三角：调整任一参数，其余参数自动联动以保持正确曝光',
              style: TextStyle(color: Colors.blue[300], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateIso(double ev, double aperture, double shutter) {
    // ISO = N² * baseIso / (2^EV * t)
    final iso = (aperture * aperture * ExposureConstants.baseIso) /
        (math.pow(2, ev) * shutter);
    return iso.round().clamp(ExposureConstants.minIso, ExposureConstants.maxIso);
  }

  double _calculateShutter(double ev, double aperture, int iso) {
    // t = N² * baseIso / (2^EV * ISO)
    final shutter = (aperture * aperture * ExposureConstants.baseIso) /
        (math.pow(2, ev) * iso);
    return shutter.clamp(ExposureConstants.minShutter, ExposureConstants.maxShutter);
  }

  String _shutterToString(double shutter) {
    if (shutter >= 1) {
      return '${shutter.toStringAsFixed(0)}s';
    } else {
      final denominator = (1 / shutter).round();
      return '1/$denominator';
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
}

// Helper function to get quality position (0.0 - 1.0)
double _getQualityPosition(int iso) {
  if (iso <= 100) return 0.0;
  if (iso <= 200) return 0.15;
  if (iso <= 400) return 0.35;
  if (iso <= 800) return 0.55;
  if (iso <= 1600) return 0.75;
  return 1.0;
}