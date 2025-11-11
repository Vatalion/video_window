import 'dart:async';
import 'package:flutter/scheduler.dart';

/// Performance monitoring service for feed
/// PERF-001: Frame time tracking and jank detection
/// AC4: Performance monitoring integration
class FeedPerformanceService {
  final List<Duration> _frameTimes = [];
  static const int _maxFrameSamples = 120; // 2 seconds at 60fps
  static const Duration _targetFrameTime = Duration(milliseconds: 16); // 60fps

  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _frameTimes.clear();

    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
    _monitoringTimer?.cancel();
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

  /// Get performance metrics
  /// AC5: Includes preload queue depth and cache metrics
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
      // AC5: Preload and cache metrics
      if (preloadQueueDepth != null) 'preloadQueueDepth': preloadQueueDepth,
      if (cacheHitRate != null) 'cacheHitRate': cacheHitRate,
      if (cacheEvictionCount != null) 'cacheEvictionCount': cacheEvictionCount,
    };
  }

  /// Reset metrics
  void reset() {
    _frameTimes.clear();
  }

  /// AC5: Emit Datadog metrics for preload and cache
  /// TODO: Integrate Datadog SDK when available
  void emitDatadogMetrics({
    int? preloadQueueDepth,
    int? cacheEvictionCount,
    int? cacheHitRate,
  }) {
    // AC5: Emit Datadog gauge feed.preload.queue_depth
    if (preloadQueueDepth != null) {
      // TODO: Integrate Datadog SDK
      // datadog.gauge('feed.preload.queue_depth', preloadQueueDepth);
    }

    // AC5: Emit Datadog counter feed.cache.evictions
    if (cacheEvictionCount != null && cacheEvictionCount > 0) {
      // TODO: Integrate Datadog SDK
      // datadog.increment('feed.cache.evictions', cacheEvictionCount);
    }

    // AC5: Emit Datadog gauge feed.cache.hit_rate
    if (cacheHitRate != null) {
      // TODO: Integrate Datadog SDK
      // datadog.gauge('feed.cache.hit_rate', cacheHitRate);
    }
  }
}
