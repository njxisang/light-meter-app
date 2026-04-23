/// 光感数据模型
class LightReading {
  /// 环境照度 (0.1 - 100000+ lux)
  final double lux;

  /// 采样时间
  final DateTime timestamp;

  /// 传感器精度等级 (0-3)
  final int accuracy;

  const LightReading({
    required this.lux,
    required this.timestamp,
    this.accuracy = 0,
  });

  /// 从传感器事件创建
  factory LightReading.fromLux(double lux, {int accuracy = 0}) {
    return LightReading(
      lux: lux,
      timestamp: DateTime.now(),
      accuracy: accuracy,
    );
  }

  /// 判断是否为有效值
  bool get isValid => lux > 0 && lux < 1000000;

  @override
  String toString() => 'LightReading(lux: $lux, timestamp: $timestamp)';
}
