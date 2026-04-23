import 'dart:math' as math;
import '../constants/exposure_constants.dart';

/// 曝光计算工具类
class ExposureCalculator {
  ExposureCalculator._();

  /// 计算曝光值 EV
  /// 简化公式：EV ≈ log2(Lux * 0.2)
  static double calculateEV(double lux) {
    if (lux <= 0) return ExposureConstants.minEv;
    return (math.log(lux * 0.2) / math.ln2)
        .clamp(ExposureConstants.minEv, ExposureConstants.maxEv);
  }

  /// 根据模式调整目标EV
  static double applyModeAdjustment(double ev, String mode) {
    switch (mode) {
      case 'portrait':
        // 人像模式：略微欠曝一点，让背景稍暗突出主体
        return ev - 0.3;
      case 'landscape':
        // 风景模式：略微过曝一点，保证暗部细节
        return ev + 0.3;
      case 'sports':
        // 运动模式：保持原EV，保证快门速度
        return ev;
      case 'lowlight':
        // 暗光模式：允许欠曝，优先降噪
        return ev - 0.7;
      case 'auto':
      default:
        return ev;
    }
  }

  /// 计算推荐快门速度
  static double calculateShutterValue({
    required double ev,
    required double aperture,
    required String mode,
  }) {
    double targetEV = applyModeAdjustment(ev, mode);

    // 基础曝光方程: t = N² / (2^EV * ISO) * baseExposure
    double shutterValue = math.pow(aperture, 2) *
        ExposureConstants.baseIso /
        (math.pow(2, targetEV) * 100);

    return shutterValue.clamp(ExposureConstants.minShutter, ExposureConstants.maxShutter);
  }

  /// 找到最近的标准快门值
  static String nearestStandardShutter(double shutterValue) {
    final shutters = ExposureConstants.standardShutters;
    double nearest = shutters.first;
    double minDiff = (shutterValue - nearest).abs();

    for (final shutter in shutters) {
      final diff = (shutterValue - shutter).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = shutter;
      }
    }

    return shutterToString(nearest);
  }

  /// 快门值转字符串
  static String shutterToString(double shutter) {
    if (shutter >= 1) {
      return '${shutter.toStringAsFixed(0)}s';
    } else {
      final denominator = (1 / shutter).round();
      return '1/${denominator}s';
    }
  }

  /// 计算推荐ISO
  static int calculateISO({
    required double lux,
    required double shutterValue,
    required double ev,
  }) {
    // 反推ISO: ISO = N² * baseIso / (2^EV * t)
    int iso = (math.pow(ExposureConstants.aperture, 2) *
            ExposureConstants.baseIso /
            (math.pow(2, ev) * shutterValue))
        .round();

    return iso.clamp(ExposureConstants.minIso, ExposureConstants.maxIso);
  }

  /// 判断曝光状态
  static String getExposureStatus(double ev, double targetEv) {
    final diff = targetEv - ev;
    if (diff > 0.5) return 'over';   // 过曝
    if (diff < -0.5) return 'under'; // 欠曝
    return 'normal';
  }

  /// 判断场景类型
  static String getScene(double lux) {
    final ranges = ExposureConstants.sceneRanges;
    for (final entry in ranges.entries) {
      final range = entry.value;
      if (lux >= range[0] && lux < range[1]) {
        return entry.key;
      }
    }
    return '晴天';
  }
}
