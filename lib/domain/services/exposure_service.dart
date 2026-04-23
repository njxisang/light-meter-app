import '../../core/constants/exposure_constants.dart';
import '../../core/utils/exposure_calculator.dart';
import '../models/exposure_recommendation.dart';

/// 曝光推荐组合
class ExposureCombination {
  final int iso;
  final String shutterSpeed;
  final double shutterValue;
  final double aperture;
  final String quality;

  const ExposureCombination({
    required this.iso,
    required this.shutterSpeed,
    required this.shutterValue,
    required this.aperture,
    required this.quality,
  });
}

/// 曝光服务 - 核心业务逻辑
class ExposureService {
  /// 计算曝光推荐
  ExposureRecommendation calculate({
    required double lux,
    required String mode,
    double? aperture,
  }) {
    final effectiveAperture = aperture ?? ExposureConstants.aperture;

    // 1. 计算EV
    double ev = ExposureCalculator.calculateEV(lux);

    // 2. 计算快门值
    double shutterValue = ExposureCalculator.calculateShutterValue(
      ev: ev,
      aperture: effectiveAperture,
      mode: mode,
    );

    // 3. 获取标准快门字符串
    String shutterSpeed = ExposureCalculator.nearestStandardShutter(shutterValue);

    // 4. 计算推荐ISO
    int iso = ExposureCalculator.calculateISO(
      lux: lux,
      shutterValue: shutterValue,
      ev: ev,
    );

    // 5. 判断场景
    String scene = ExposureCalculator.getScene(lux);

    // 6. 判断曝光状态
    double targetEv = ExposureCalculator.applyModeAdjustment(ev, mode);
    String exposureStatus = ExposureCalculator.getExposureStatus(ev, targetEv);

    // 7. 检查警告
    String? warning = _checkWarning(lux, iso, shutterValue, mode);

    return ExposureRecommendation.calculate(
      lux: lux,
      mode: mode,
      ev: ev,
      shutterSpeed: shutterSpeed,
      shutterValue: shutterValue,
      iso: iso,
      scene: scene,
      exposureStatus: exposureStatus,
      warning: warning,
    );
  }

  /// 计算多个曝光组合（用于推荐多个参数组合）
  List<ExposureCombination> calculateMultipleCombinations({
    required double lux,
    required String mode,
  }) {
    final combinations = <ExposureCombination>[];
    final ev = ExposureCalculator.calculateEV(lux);

    for (final aperture in ExposureConstants.apertureOptions) {
      // 对每个光圈值计算最优组合
      final shutterValue = ExposureCalculator.calculateShutterValue(
        ev: ev,
        aperture: aperture,
        mode: mode,
      );

      final shutterSpeed = ExposureCalculator.nearestStandardShutter(shutterValue);
      final iso = ExposureCalculator.calculateISO(
        lux: lux,
        shutterValue: shutterValue,
        ev: ev,
      );

      // 评估组合质量
      String quality = _evaluateCombination(iso, shutterValue);

      combinations.add(ExposureCombination(
        iso: iso,
        shutterSpeed: shutterSpeed,
        shutterValue: shutterValue,
        aperture: aperture,
        quality: quality,
      ));
    }

    return combinations;
  }

  String _evaluateCombination(int iso, double shutterValue) {
    // 基于ISO评估
    if (iso <= 100) return '优秀';
    if (iso <= 400) return '良好';
    if (iso <= 800) return '一般';
    return '噪点较多';
  }

  /// 检查警告信息
  String? _checkWarning(double lux, int iso, double shutterValue, String mode) {
    if (lux < 0.1) {
      return '光线极弱，建议使用补光灯';
    }

    if (iso == ExposureConstants.maxIso && mode != 'lowlight') {
      return 'ISO已达上限，画面可能产生噪点';
    }

    if (iso == ExposureConstants.minIso &&
        shutterValue >= ExposureConstants.maxShutter) {
      return '光线过强，建议使用减光镜或选择阴凉处';
    }

    // 检查快门速度是否在安全范围
    if (shutterValue > 1 / 30 && mode == 'sports') {
      return '快门速度较慢，建议增加ISO或选择运动模式';
    }

    return null;
  }

  /// 计算安全快门速度（基于焦距）
  /// 手机等效焦距约24-28mm，安全快门约1/60s
  static double getSafeShutter({double focalLength = 24}) {
    return 1 / (focalLength * 2);
  }
}
