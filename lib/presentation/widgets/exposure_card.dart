import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/exposure_constants.dart';
import '../../core/utils/exposure_calculator.dart';
import '../providers/light_sensor_provider.dart';

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
            ],
          ),
          const SizedBox(height: 20),

          // 三个参数选择器
          _buildParamSelectors(context, ref, selectedAperture, selectedIso, selectedShutter, optimalIso, optimalShutter),

          const SizedBox(height: 16),

          // 实时参数显示
          _buildRealtimeParams(selectedIso, optimalIso, selectedShutter, optimalShutter),

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

  Widget _buildRealtimeParams(int selectedIso, int optimalIso, double selectedShutter, double optimalShutter) {
    final isoDiff = (selectedIso - optimalIso).abs();
    final shutterDiff = (selectedShutter - optimalShutter).abs();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildParamDisplay('当前ISO', selectedIso.toString(), _getIsoColor(selectedIso)),
        _buildParamDisplay('当前快门', _shutterToString(selectedShutter), Colors.white),
        _buildParamDisplay('偏差', isoDiff <= 50 ? '✓ 正常' : '↑↓ 调整', isoDiff <= 50 ? Colors.green : Colors.orange),
      ],
    );
  }

  Widget _buildParamDisplay(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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

  Color _getIsoColor(int iso) {
    if (iso <= 100) return Colors.green;
    if (iso <= 400) return Colors.lightGreen;
    if (iso <= 800) return Colors.yellow;
    if (iso <= 1600) return Colors.orange;
    return Colors.red;
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