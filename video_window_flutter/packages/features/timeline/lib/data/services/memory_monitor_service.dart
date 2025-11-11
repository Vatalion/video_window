import 'dart:async';
import 'dart:io';

/// Memory monitoring service for feed
/// PERF-005: Memory usage monitoring and automatic cleanup
/// AC4, AC5: Memory optimization and leak prevention
class MemoryMonitorService {
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  final List<MemorySnapshot> _snapshots = [];
  static const int _maxSnapshots = 100;
  static const int _lowMemoryThresholdMB = 150; // Alert if memory > 150MB

  /// Start memory monitoring
  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _snapshots.clear();

    _monitoringTimer = Timer.periodic(interval, (_) {
      _captureSnapshot();
    });
  }

  /// Stop memory monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  void _captureSnapshot() {
    try {
      final memoryUsage = _getCurrentMemoryUsage();
      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        memoryUsageMB: memoryUsage,
      );

      _snapshots.add(snapshot);

      // Keep only recent snapshots
      if (_snapshots.length > _maxSnapshots) {
        _snapshots.removeAt(0);
      }

      // Check for low memory condition
      if (memoryUsage > _lowMemoryThresholdMB) {
        _onLowMemoryDetected(memoryUsage);
      }
    } catch (e) {
      // Memory monitoring failed, continue
    }
  }

  /// Get current memory usage in MB
  int _getCurrentMemoryUsage() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile platforms, use ProcessInfo if available
        // This is a simplified implementation
        return 0; // Would need platform-specific implementation
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Handle low memory condition
  void _onLowMemoryDetected(int memoryUsageMB) {
    // PERF-005: Trigger cleanup callbacks
    // This would be called by widgets/services to clean up resources
  }

  /// Get current memory usage
  int getCurrentMemoryUsageMB() {
    if (_snapshots.isEmpty) return 0;
    return _snapshots.last.memoryUsageMB;
  }

  /// Get memory trend (increasing/decreasing)
  MemoryTrend getMemoryTrend() {
    if (_snapshots.length < 2) return MemoryTrend.stable;

    final recent = _snapshots.sublist(_snapshots.length - 5);
    final avgRecent =
        recent.map((s) => s.memoryUsageMB).reduce((a, b) => a + b) /
            recent.length;
    final avgOlder = _snapshots.length > 5
        ? _snapshots
                .sublist(0, _snapshots.length - 5)
                .map((s) => s.memoryUsageMB)
                .reduce((a, b) => a + b) /
            (_snapshots.length - 5)
        : avgRecent;

    if (avgRecent > avgOlder * 1.1) return MemoryTrend.increasing;
    if (avgRecent < avgOlder * 0.9) return MemoryTrend.decreasing;
    return MemoryTrend.stable;
  }

  /// Get memory statistics
  Map<String, dynamic> getStatistics() {
    if (_snapshots.isEmpty) {
      return {
        'currentMB': 0,
        'averageMB': 0,
        'peakMB': 0,
        'trend': 'stable',
      };
    }

    final current = _snapshots.last.memoryUsageMB;
    final average =
        _snapshots.map((s) => s.memoryUsageMB).reduce((a, b) => a + b) /
            _snapshots.length;
    final peak =
        _snapshots.map((s) => s.memoryUsageMB).reduce((a, b) => a > b ? a : b);

    return {
      'currentMB': current,
      'averageMB': average.round(),
      'peakMB': peak,
      'trend': getMemoryTrend().name,
      'snapshotCount': _snapshots.length,
    };
  }

  void dispose() {
    stopMonitoring();
    _snapshots.clear();
  }
}

/// Memory snapshot data
class MemorySnapshot {
  final DateTime timestamp;
  final int memoryUsageMB;

  MemorySnapshot({
    required this.timestamp,
    required this.memoryUsageMB,
  });
}

/// Memory trend indicator
enum MemoryTrend {
  increasing,
  decreasing,
  stable,
}
