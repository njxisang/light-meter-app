import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/exposure_constants.dart';
import '../../core/utils/exposure_calculator.dart';
import '../../data/repositories/light_sensor_repository.dart';
import '../../domain/models/light_reading.dart';
import '../../domain/models/exposure_recommendation.dart';
import '../../domain/services/exposure_service.dart';
import '../../providers.dart';

/// 光线传感器仓库 Provider
final lightSensorRepositoryProvider = Provider<LightSensorRepository>((ref) {
  final repository = LightSensorRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

/// 曝光服务 Provider
final exposureServiceProvider = Provider<ExposureService>((ref) {
  return ExposureService();
});

/// 当前拍摄模式 Provider
final shootingModeProvider = StateProvider<String>((ref) {
  return ref.watch(sharedPreferencesProvider).getString('settings_shooting_mode') ?? 'auto';
});

/// 当前选择的光圈 Provider
final apertureProvider = StateProvider<double>((ref) {
  return ref.watch(sharedPreferencesProvider).getDouble('settings_aperture') ?? ExposureConstants.aperture;
});

/// 当前选择的ISO Provider
final isoProvider = StateProvider<int>((ref) {
  return ref.watch(sharedPreferencesProvider).getInt('settings_iso') ?? 100;
});

/// 当前选择的快门速度 Provider
final shutterProvider = StateProvider<double>((ref) {
  return ref.watch(sharedPreferencesProvider).getDouble('settings_shutter') ?? (1 / 125);
});

/// 计算的目标EV Provider（由lux和mode自动推导）
final exposureEvProvider = Provider<double>((ref) {
  final sensorState = ref.watch(lightSensorProvider);
  final mode = ref.watch(shootingModeProvider);
  if (sensorState.currentReading == null) return 10.0;
  final ev = ExposureCalculator.calculateEV(sensorState.currentReading!.lux);
  return ExposureCalculator.applyModeAdjustment(ev, mode);
});

/// 传感器采样间隔 Provider（毫秒）
final sensorIntervalMsProvider = StateProvider<int>((ref) {
  return ref.watch(sharedPreferencesProvider).getInt('settings_sensor_interval_ms') ?? 50;
});

/// 数据平滑采样次数 Provider
final smoothSizeProvider = StateProvider<int>((ref) {
  return ref.watch(sharedPreferencesProvider).getInt('settings_smooth_size') ?? 5;
});

/// 传感器可用性 Provider
final sensorAvailableProvider = FutureProvider<bool>((ref) async {
  return LightSensorRepository.isAvailable();
});

/// 光感数据状态
class LightSensorState {
  final LightReading? currentReading;
  final List<LightReading> history;
  final bool isAvailable;
  final String? error;

  const LightSensorState({
    this.currentReading,
    this.history = const [],
    this.isAvailable = true,
    this.error,
  });

  LightSensorState copyWith({
    LightReading? currentReading,
    List<LightReading>? history,
    bool? isAvailable,
    String? error,
  }) {
    return LightSensorState(
      currentReading: currentReading ?? this.currentReading,
      history: history ?? this.history,
      isAvailable: isAvailable ?? this.isAvailable,
      error: error,
    );
  }
}

/// 光感数据 Notifier
class LightSensorNotifier extends StateNotifier<LightSensorState> {
  final LightSensorRepository _repository;
  StreamSubscription<LightReading>? _subscription;

  // 平滑后的lux值
  List<double> _smoothBuffer = [];
  int _smoothSize = ExposureConstants.smoothSize;

  LightSensorNotifier(this._repository)
      : super(const LightSensorState()) {
    _init();
  }

  Future<void> _init() async {
    final available = await LightSensorRepository.isAvailable();
    state = state.copyWith(isAvailable: available);

    if (available) {
      _repository.startListening(
        interval: const Duration(milliseconds: ExposureConstants.sensorIntervalMs),
      );

      _subscription = _repository.lightStream.listen(
        (LightReading reading) {
          _addReading(reading);
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      );
    }
  }

  /// 更新平滑参数（由设置页面调用）
  void updateSmoothParams({int? intervalMs, int? smoothSize}) {
    if (intervalMs != null) {
      _repository.startListening(interval: Duration(milliseconds: intervalMs));
    }
    if (smoothSize != null) {
      _smoothSize = smoothSize;
      // 调整缓冲区大小
      if (_smoothBuffer.length > _smoothSize) {
        _smoothBuffer = _smoothBuffer.sublist(_smoothBuffer.length - _smoothSize);
      }
    }
  }

  void _addReading(LightReading reading) {
    // 更新平滑缓冲区
    _smoothBuffer.add(reading.lux);
    if (_smoothBuffer.length > _smoothSize) {
      _smoothBuffer.removeAt(0);
    }

    // 计算平滑值
    final smoothedLux = _smoothBuffer.reduce((a, b) => a + b) / _smoothBuffer.length;

    // 更新历史
    final newHistory = List<LightReading>.from(state.history);
    newHistory.add(LightReading.fromLux(smoothedLux));
    if (newHistory.length > ExposureConstants.historyLength) {
      newHistory.removeAt(0);
    }

    state = state.copyWith(
      currentReading: LightReading.fromLux(smoothedLux),
      history: newHistory,
    );
  }

  void startManualMode(double lux) {
    final reading = LightReading.fromLux(lux);
    _addReading(reading);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// 光感数据 Provider
final lightSensorProvider =
    StateNotifierProvider<LightSensorNotifier, LightSensorState>((ref) {
  final repository = ref.watch(lightSensorRepositoryProvider);
  return LightSensorNotifier(repository);
});

/// 曝光推荐 Provider
final exposureRecommendationProvider = Provider<ExposureRecommendation?>((ref) {
  final sensorState = ref.watch(lightSensorProvider);
  final mode = ref.watch(shootingModeProvider);
  final exposureService = ref.watch(exposureServiceProvider);

  if (sensorState.currentReading == null) {
    return null;
  }

  return exposureService.calculate(
    lux: sensorState.currentReading!.lux,
    mode: mode,
  );
});
