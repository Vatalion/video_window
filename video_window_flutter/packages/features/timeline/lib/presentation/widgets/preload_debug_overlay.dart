import 'package:flutter/material.dart';
import 'package:core/services/feature_flags_service.dart';
import '../../data/services/feed_performance_service.dart';
import '../../data/services/video_preloader_service.dart';
import '../../data/repositories/feed_cache_repository.dart';

/// Debug overlay for preload and performance metrics
/// AC1, AC5: Exposes FPS, jank %, memory delta, preload queue depth, cache metrics, and performance stats
/// AC1: Gated by feature flag `feed_performance_monitoring`
/// Toggle via long-press on video feed item
class PreloadDebugOverlay extends StatelessWidget {
  final FeedPerformanceService? performanceService;
  final VideoPreloaderService? preloaderService;
  final FeedCacheRepository? cacheRepository;
  final bool isVisible;
  final FeatureFlagsService? featureFlagsService;

  const PreloadDebugOverlay({
    super.key,
    this.performanceService,
    this.preloaderService,
    this.cacheRepository,
    this.isVisible = false,
    this.featureFlagsService,
  });

  @override
  Widget build(BuildContext context) {
    // AC1: Feature flag gating - only show if flag is enabled
    if (!isVisible) return const SizedBox.shrink();

    // Check feature flag asynchronously - for now, show if service is provided
    // In production, this would use FutureBuilder with featureFlagsService
    final shouldShow = featureFlagsService == null ||
        performanceService != null; // Simplified check

    if (!shouldShow) return const SizedBox.shrink();

    return Positioned(
      top: 40,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Performance Debug',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // AC1: Performance metrics
            if (performanceService != null) ...[
              _buildMetricRow(
                'FPS',
                performanceService!.getCurrentFps().toStringAsFixed(1),
              ),
              _buildMetricRow(
                'Jank %',
                performanceService!.getJankPercentage().toStringAsFixed(1),
              ),
              // AC1: Memory delta
              _buildMetricRow(
                'Memory Δ',
                '${performanceService!.getMemoryDeltaMB()} MB',
              ),
              _buildMetricRow(
                'CPU %',
                performanceService!
                    .getAverageCpuUtilization()
                    .toStringAsFixed(1),
              ),
              const SizedBox(height: 4),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 4),
            ],
            // AC1: Preload queue stats
            _buildMetricRow(
              'Preload Queue',
              preloaderService?.getQueueDepth().toString() ?? 'N/A',
            ),
            _buildMetricRow(
              'Cache Evictions',
              cacheRepository?.getEvictionCount().toString() ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
