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
  bool get isBatterySaverMode => _currentState == BatteryState.charging;

  /// Check if battery is low
  Future<bool> isBatteryLow() async {
    final level = await _battery.batteryLevel;
    return level < 20;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
