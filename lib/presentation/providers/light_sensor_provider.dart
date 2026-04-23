import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/exposure_constants.dart';
import '../../data/repositories/light_sensor_repository.dart';
import '../../domain/models/light_reading.dart';
import '../../domain/models/exposure_recommendation.dart';
import '../../domain/services/exposure_service.dart';

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
final shootingModeProvider = StateProvider<String>((ref) => 'auto');

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
  final List<double> _smoothBuffer = [];
  static const int _smoothSize = 10;

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
