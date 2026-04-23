/// 曝光计算常量
class ExposureConstants {
  ExposureConstants._();

  /// 手机固定光圈
  static const double aperture = 1.8;

  /// ISO范围
  static const int minIso = 50;
  static const int maxIso = 3200;

  /// 基准ISO
  static const int baseIso = 100;

  /// 快门速度范围（秒）
  static const double minShutter = 1 / 8000;
  static const double maxShutter = 1.0;

  /// EV范围
  static const double minEv = -4;
  static const double maxEv = 16;

  /// 标准快门序列
  static const List<double> standardShutters = [
    1 / 8000,
    1 / 4000,
    1 / 2000,
    1 / 1000,
    1 / 500,
    1 / 250,
    1 / 125,
    1 / 60,
    1 / 30,
    1 / 15,
    1 / 8,
    1 / 4,
    1 / 2,
    1,
  ];

  /// 传感器采样间隔（毫秒）
  static const int sensorIntervalMs = 100;

  /// 历史数据点数
  static const int historyLength = 300; // 30秒 * 10次/秒

  /// 场景Lux范围定义
  static const Map<String, List<double>> sceneRanges = {
    '晴天': [10000, double.infinity],
    '多云': [1000, 10000],
    '阴天': [500, 1000],
    '室内晴天': [100, 500],
    '室内灯光': [50, 200],
    '黄昏': [10, 50],
    '暗光': [0, 10],
  };
}
