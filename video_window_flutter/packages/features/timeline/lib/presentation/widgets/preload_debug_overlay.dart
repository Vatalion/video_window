import 'package:flutter/material.dart';
import '../../data/services/feed_performance_service.dart';
import '../../data/services/video_preloader_service.dart';
import '../../data/repositories/feed_cache_repository.dart';

/// Debug overlay for preload and performance metrics
/// AC1, AC5: Exposes preload queue depth, cache metrics, and performance stats
/// Toggle via long-press on video feed item
class PreloadDebugOverlay extends StatelessWidget {
  final FeedPerformanceService? performanceService;
  final VideoPreloaderService? preloaderService;
  final FeedCacheRepository? cacheRepository;
  final bool isVisible;

  const PreloadDebugOverlay({
    super.key,
    this.performanceService,
    this.preloaderService,
    this.cacheRepository,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

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
              'Preload Debug',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildMetricRow(
              'Preload Queue',
              preloaderService?.getQueueDepth().toString() ?? 'N/A',
            ),
            _buildMetricRow(
              'Cache Evictions',
              cacheRepository?.getEvictionCount().toString() ?? 'N/A',
            ),
            if (performanceService != null) ...[
              const SizedBox(height: 4),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 4),
              _buildMetricRow(
                'FPS',
                performanceService!.getCurrentFps().toStringAsFixed(1),
              ),
              _buildMetricRow(
                'Jank %',
                performanceService!.getJankPercentage().toStringAsFixed(1),
              ),
            ],
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
