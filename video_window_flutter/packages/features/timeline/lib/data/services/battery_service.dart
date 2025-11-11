import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

/// Battery service for battery-saver mode detection
/// PERF-002: Battery-saver mode detection for auto-play decisions
class BatteryService {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _subscription;
  BatteryState _currentState = BatteryState.unknown;

  BatteryService() {
    _init();
  }

  Future<void> _init() async {
    _currentState = await _battery.batteryState;
    _subscription = _battery.onBatteryStateChanged.listen((state) {
      _currentState = state;
    });
  }

  /// Check if battery saver mode is active
  /// AC5: Battery saver mode detection for auto-play/prefetch disabling
  /// Note: battery_plus doesn't directly expose battery saver mode, so we use
  /// low battery level (< 20%) as a proxy. For true battery saver detection,
  /// platform channels would be needed.
  Future<bool> isBatterySaverMode() async {
    final level = await _battery.batteryLevel;
    // Consider battery saver active if battery is low (< 20%) or discharging
    // In production, this should use platform channels for true battery saver detection
    return level < 20 || _currentState == BatteryState.discharging;
  }

  /// Check if battery is low
  Future<bool> isBatteryLow() async {
    final level = await _battery.batteryLevel;
    return level < 20;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
