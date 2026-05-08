/// 曝光计算常量
class ExposureConstants {
  ExposureConstants._();

  /// 手机固定光圈
  static const double aperture = 1.8;

  /// 可选光圈列表（手机镜头可模拟的光圈值）
  static const List<double> apertureOptions = [1.8, 2.0, 2.8, 4.0, 5.6, 8.0];

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

  /// 传感器采样间隔（毫秒）- 更灵敏的采样
  static const int sensorIntervalMs = 50;

  /// 数据平滑采样次数
  static const int smoothSize = 5;

  /// 历史数据点数
  static const int historyLength = 300; // 30秒 * 10次/秒

  /// 场景Lux范围定义 [min, max)
  /// 注意：范围不能重叠，否则优先匹配前面的
  static const Map<String, List<double>> sceneRanges = {
    '暗光': [0, 10],
    '黄昏': [10, 50],
    '室内灯光': [50, 200],
    '室内晴天': [200, 500],
    '阴天': [500, 1000],
    '多云': [1000, 10000],
    '晴天': [10000, double.infinity],
  };
}
