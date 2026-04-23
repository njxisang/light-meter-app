# Light Meter - 光照计

📷 基于手机光线传感器的摄影曝光参数推荐应用

## 功能特性

### 核心功能
- **实时Lux监测** - 每100ms采样，10次平滑，实时显示环境照度
- **场景自动识别** - 支持7种场景：晴天、多云、阴天、室内晴天、室内灯光、黄昏、暗光
- **曝光参数推荐** - 基于EV公式计算推荐ISO和快门速度
- **5种拍摄模式** - 自动/人像/风景/运动/暗光

### 界面展示
- 深色主题，护眼设计
- 实时Lux数值显示
- 曝光参数卡片(ISO/快门/光圈/曝光状态)
- 30秒历史曲线图

## 技术栈

| 技术 | 说明 |
|------|------|
| Flutter | 3.24.0 (Dart 3.5.0) |
| 状态管理 | Riverpod |
| 架构 | Clean Architecture |
| 传感器 | Android Platform Channel (原生光线传感器) |

## 项目结构

```
lib/
├── main.dart
├── core/
│   ├── constants/exposure_constants.dart   # 曝光常量
│   └── utils/exposure_calculator.dart     # 曝光计算
├── data/
│   └── repositories/light_sensor_repository.dart
├── domain/
│   ├── models/
│   │   ├── light_reading.dart
│   │   └── exposure_recommendation.dart
│   └── services/exposure_service.dart
└── presentation/
    ├── providers/light_sensor_provider.dart
    ├── screens/home_screen.dart
    └── widgets/
        ├── lux_display.dart
        ├── exposure_card.dart
        ├── scene_selector.dart
        └── history_chart.dart
```

## 曝光计算原理

基于标准曝光方程：

```
EV = log2(N² / t) = log2(Lux × C / (ISO × K))
```

- N: 光圈 (手机固定 f/1.8)
- t: 快门时间
- Lux: 实测照度
- K: 校准常数 (12.5)
- C: 转换常数 (0.5)

## 开发

```bash
# 安装依赖
flutter pub get

# 运行
flutter run

# 构建
flutter build apk --debug
```

## 版本

- **最低Android版本**: API 21 (Android 5.0)
- **推荐Android版本**: API 26+ (Android 8.0+)
