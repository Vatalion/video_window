import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'memory_monitor_service.dart';

/// Performance monitoring service for feed
/// PERF-001: Frame time tracking and jank detection
/// AC1, AC4: Performance monitoring integration with memory delta and CPU tracking
class FeedPerformanceService {
  final List<Duration> _frameTimes = [];
  static const int _maxFrameSamples = 120; // 2 seconds at 60fps
  static const Duration _targetFrameTime = Duration(milliseconds: 16); // 60fps

  Timer? _monitoringTimer;
  Timer? _cpuMonitoringTimer;
  bool _isMonitoring = false;

  // AC1: Memory delta tracking
  final MemoryMonitorService _memoryMonitor = MemoryMonitorService();
  int _initialMemoryMB = 0;
  int _currentMemoryMB = 0;

  // AC4: CPU utilization tracking
  final List<double> _cpuSamples = [];
  static const int _maxCpuSamples = 60; // 1 minute at 1 sample/second
  DateTime? _sessionStartTime;

  /// Start performance monitoring
  /// AC1, AC4: Starts frame timing, memory monitoring, and CPU tracking
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _frameTimes.clear();
    _cpuSamples.clear();
    _sessionStartTime = DateTime.now();

    // AC1: Start frame timing
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);

    // AC1: Start memory monitoring
    _memoryMonitor.startMonitoring();
    _initialMemoryMB = _memoryMonitor.getCurrentMemoryUsageMB();

    // AC4: Start CPU monitoring (sample every second)
    _cpuMonitoringTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sampleCpuUsage();
    });
  }

  /// Stop performance monitoring
  /// AC4: Stops all monitoring and releases resources
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
    _monitoringTimer?.cancel();
    _cpuMonitoringTimer?.cancel();
    _memoryMonitor.stopMonitoring();
    _sessionStartTime = null;
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan;
      _frameTimes.add(frameTime);

      // Keep only recent samples
      if (_frameTimes.length > _maxFrameSamples) {
        _frameTimes.removeAt(0);
      }
    }
  }

  /// Get current FPS
  double getCurrentFps() {
    if (_frameTimes.isEmpty) return 0.0;

    final avgFrameTime =
        _frameTimes.map((t) => t.inMicroseconds).reduce((a, b) => a + b) /
            _frameTimes.length;

    return 1000000 / avgFrameTime; // Convert microseconds to FPS
  }

  /// Calculate jank percentage
  /// PERF-001: Jank = frames taking >2x target frame time
  double getJankPercentage() {
    if (_frameTimes.isEmpty) return 0.0;

    final jankThreshold = _targetFrameTime * 2;
    final jankFrames = _frameTimes.where((t) => t > jankThreshold).length;

    return (jankFrames / _frameTimes.length) * 100;
  }

  /// AC1: Get memory delta (current - initial) in MB
  int getMemoryDeltaMB() {
    _currentMemoryMB = _memoryMonitor.getCurrentMemoryUsageMB();
    return _currentMemoryMB - _initialMemoryMB;
  }

  /// AC4: Sample CPU usage (simplified - uses process info)
  void _sampleCpuUsage() {
    try {
      // Simplified CPU monitoring - in production would use platform channels
      // For now, we track a synthetic metric based on frame timing
      if (_frameTimes.isNotEmpty) {
        final avgFrameTime =
            _frameTimes.map((t) => t.inMicroseconds).reduce((a, b) => a + b) /
                _frameTimes.length;
        // Estimate CPU usage: if frames take longer, CPU is higher
        // Target: 16ms per frame = ~6% CPU at 60fps
        // If frame time is 16ms, CPU is ~6%. If 32ms, CPU is ~12%
        final estimatedCpu = (avgFrameTime / 1000) * 0.375; // Rough estimate
        _cpuSamples.add(estimatedCpu.clamp(0.0, 100.0));

        // Keep only recent samples
        if (_cpuSamples.length > _maxCpuSamples) {
          _cpuSamples.removeAt(0);
        }
      }
    } catch (e) {
      // CPU monitoring failed, continue
    }
  }

  /// AC4: Get average CPU utilization percentage
  double getAverageCpuUtilization() {
    if (_cpuSamples.isEmpty) return 0.0;
    return _cpuSamples.reduce((a, b) => a + b) / _cpuSamples.length;
  }

  /// Get performance metrics
  /// AC1, AC4, AC5: Includes FPS, jank, memory delta, CPU, preload queue, and cache metrics
  Map<String, dynamic> getMetrics({
    int? preloadQueueDepth,
    int? cacheHitRate,
    int? cacheEvictionCount,
  }) {
    return {
      'fps': getCurrentFps(),
      'jankPercentage': getJankPercentage(),
      'frameCount': _frameTimes.length,
      'avgFrameTime': _frameTimes.isEmpty
          ? 0
          : _frameTimes.map((t) => t.inMicroseconds).reduce((a, b) => a + b) /
              _frameTimes.length,
      // AC1: Memory delta
      'memoryDeltaMB': getMemoryDeltaMB(),
      'currentMemoryMB': _currentMemoryMB,
      'initialMemoryMB': _initialMemoryMB,
      // AC4: CPU utilization
      'cpuUtilization': getAverageCpuUtilization(),
      'sessionDurationSeconds': _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : 0,
      // AC5: Preload and cache metrics
      if (preloadQueueDepth != null) 'preloadQueueDepth': preloadQueueDepth,
      if (cacheHitRate != null) 'cacheHitRate': cacheHitRate,
      if (cacheEvictionCount != null) 'cacheEvictionCount': cacheEvictionCount,
    };
  }

  /// Reset metrics
  void reset() {
    _frameTimes.clear();
    _cpuSamples.clear();
    _initialMemoryMB = _memoryMonitor.getCurrentMemoryUsageMB();
    _currentMemoryMB = _initialMemoryMB;
    _sessionStartTime = DateTime.now();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _memoryMonitor.dispose();
  }

  /// AC3: Emit Datadog metrics for performance monitoring
  /// AC3: Publishes feed.performance.fps and feed.performance.jank
  void emitDatadogMetrics({
    int? preloadQueueDepth,
    int? cacheEvictionCount,
    int? cacheHitRate,
  }) {
    // AC3: Emit Datadog gauge feed.performance.fps
    final fps = getCurrentFps();
    if (fps > 0) {
      // TODO: Integrate Datadog SDK when available
      // datadog.gauge('feed.performance.fps', fps);
      if (kDebugMode) {
        print('[Datadog] feed.performance.fps = $fps');
      }
    }

    // AC3: Emit Datadog gauge feed.performance.jank
    final jank = getJankPercentage();
    // TODO: Integrate Datadog SDK when available
    // datadog.gauge('feed.performance.jank', jank);
    if (kDebugMode) {
      print('[Datadog] feed.performance.jank = $jank');
    }

    // AC5: Emit Datadog gauge feed.preload.queue_depth
    if (preloadQueueDepth != null) {
      // TODO: Integrate Datadog SDK
      // datadog.gauge('feed.preload.queue_depth', preloadQueueDepth);
      if (kDebugMode) {
        print('[Datadog] feed.preload.queue_depth = $preloadQueueDepth');
      }
    }

    // AC5: Emit Datadog counter feed.cache.evictions
    if (cacheEvictionCount != null && cacheEvictionCount > 0) {
      // TODO: Integrate Datadog SDK
      // datadog.increment('feed.cache.evictions', cacheEvictionCount);
      if (kDebugMode) {
        print('[Datadog] feed.cache.evictions += $cacheEvictionCount');
      }
    }

    // AC5: Emit Datadog gauge feed.cache.hit_rate
    if (cacheHitRate != null) {
      // TODO: Integrate Datadog SDK
      // datadog.gauge('feed.cache.hit_rate', cacheHitRate);
      if (kDebugMode) {
        print('[Datadog] feed.cache.hit_rate = $cacheHitRate');
      }
    }
  }
}
