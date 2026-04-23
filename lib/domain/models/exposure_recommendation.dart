/// 曝光推荐模型
class ExposureRecommendation {
  /// 推荐ISO (50-3200)
  final int iso;

  /// 快门速度字符串 "1/125s"
  final String shutterSpeed;

  /// 快门数值（秒）
  final double shutterValue;

  /// 光圈 f/1.8
  final double aperture;

  /// 曝光值
  final double ev;

  /// 场景类型
  final String scene;

  /// 曝光状态 "over" | "normal" | "under"
  final String exposureStatus;

  /// 警告信息
  final String? warning;

  const ExposureRecommendation({
    required this.iso,
    required this.shutterSpeed,
    required this.shutterValue,
    required this.aperture,
    required this.ev,
    required this.scene,
    required this.exposureStatus,
    this.warning,
  });

  /// 创建一个推荐的曝光参数
  factory ExposureRecommendation.calculate({
    required double lux,
    required String mode,
    required double ev,
    required String shutterSpeed,
    required double shutterValue,
    required int iso,
    required String scene,
    required String exposureStatus,
    String? warning,
  }) {
    return ExposureRecommendation(
      iso: iso,
      shutterSpeed: shutterSpeed,
      shutterValue: shutterValue,
      aperture: 1.8,
      ev: ev,
      scene: scene,
      exposureStatus: exposureStatus,
      warning: warning,
    );
  }

  @override
  String toString() =>
      'ExposureRecommendation(iso: $iso, shutter: $shutterSpeed, ev: $ev)';
}
