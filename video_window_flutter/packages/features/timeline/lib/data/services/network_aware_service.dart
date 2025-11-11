import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network-aware service for prefetching decisions
/// PERF-003: Network-aware prefetching (Wi-Fi vs cellular)
class NetworkAwareService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityResult _currentConnection = ConnectivityResult.none;

  NetworkAwareService() {
    _init();
  }

  Future<void> _init() async {
    _currentConnection = (await _connectivity.checkConnectivity()).first;
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _currentConnection = results.first;
    });
  }

  /// Check if connected to Wi-Fi
  bool get isWifi => _currentConnection == ConnectivityResult.wifi;

  /// Check if connected to mobile data
  bool get isMobile => _currentConnection == ConnectivityResult.mobile;

  /// Check if connected to any network
  bool get isConnected => _currentConnection != ConnectivityResult.none;

  /// Should prefetch based on network conditions
  /// PERF-003: Only prefetch on Wi-Fi or if user preference allows
  bool shouldPrefetch({bool allowMobilePrefetch = false}) {
    if (!isConnected) return false;
    if (isWifi) return true;
    if (isMobile && allowMobilePrefetch) return true;
    return false;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
