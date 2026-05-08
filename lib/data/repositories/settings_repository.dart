import 'package:shared_preferences/shared_preferences.dart';

/// 设置持久化仓库
class SettingsRepository {
  static const _keyAperture = 'settings_aperture';
  static const _keyIso = 'settings_iso';
  static const _keyShutter = 'settings_shutter';
  static const _keyShootingMode = 'settings_shooting_mode';
  static const _keySensorIntervalMs = 'settings_sensor_interval_ms';
  static const _keySmoothSize = 'settings_smooth_size';

  SharedPreferences? _prefs;

  SharedPreferences get _p {
    return _prefs ?? (throw StateError('SettingsRepository not initialized')));
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  double get aperture => _p.getDouble(_keyAperture) ?? 1.8;
  int get iso => _p.getInt(_keyIso) ?? 100;
  double get shutter => _p.getDouble(_keyShutter) ?? (1 / 125);
  String get shootingMode => _p.getString(_keyShootingMode) ?? 'auto';
  int get sensorIntervalMs => _p.getInt(_keySensorIntervalMs) ?? 50;
  int get smoothSize => _p.getInt(_keySmoothSize) ?? 5;

  Future<void> setAperture(double v) => _p.setDouble(_keyAperture, v);
  Future<void> setIso(int v) => _p.setInt(_keyIso, v);
  Future<void> setShutter(double v) => _p.setDouble(_keyShutter, v);
  Future<void> setShootingMode(String v) => _p.setString(_keyShootingMode, v);
  Future<void> setSensorIntervalMs(int v) => _p.setInt(_keySensorIntervalMs, v);
  Future<void> setSmoothSize(int v) => _p.setInt(_keySmoothSize, v);
}
