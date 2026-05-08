import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/models/light_reading.dart';

/// Android光线传感器平台通道
class LightSensorRepository {
  static const MethodChannel _channel = MethodChannel('light_meter/light_sensor');
  static const EventChannel _eventChannel = EventChannel('light_meter/light_sensor/events');

  StreamSubscription? _subscription;
  final StreamController<LightReading> _controller =
      StreamController<LightReading>.broadcast();

  /// 光线传感器事件流
  Stream<LightReading> get lightStream => _controller.stream;

  /// 是否正在监听
  bool _isListening = false;
  bool get isListening => _isListening;

  bool _isDisposed = false;

  /// 传感器可用性检查
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 开始监听光线传感器
  void startListening({Duration interval = const Duration(milliseconds: 100)}) {
    if (_isListening) return;

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final lux = (event['lux'] as num?)?.toDouble() ?? 0;
          final reading = LightReading.fromLux(lux);
          if (reading.isValid) {
            _controller.add(reading);
          }
        }
      },
      onError: (error) {
        _controller.addError(error);
      },
    );
    _isListening = true;
  }

  /// 停止监听
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  /// 释放资源
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    stopListening();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
