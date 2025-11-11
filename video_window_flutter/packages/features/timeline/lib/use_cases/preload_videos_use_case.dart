import 'package:video_player/video_player.dart';
import '../../domain/entities/video.dart';
import '../../data/services/video_preloader_service.dart';
import '../../data/services/feed_performance_service.dart';
import '../../data/services/feed_analytics_events.dart';
import 'package:core/services/analytics_service.dart';

/// Use case for preloading videos
/// AC1: Video preloader warms the previous and next two videos using controller pooling
/// and releases resources when out of range
class PreloadVideosUseCase {
  final VideoPreloaderService _preloaderService;
  final FeedPerformanceService? _performanceService;
  final AnalyticsService? _analyticsService; // AC5: For Segment events

  PreloadVideosUseCase({
    required VideoPreloaderService preloaderService,
    FeedPerformanceService? performanceService,
    AnalyticsService? analyticsService,
  })  : _preloaderService = preloaderService,
        _performanceService = performanceService,
        _analyticsService = analyticsService;

  /// Preload videos around the current index
  /// AC1: Preloads previous and next two videos (total 4 videos)
  /// Releases controllers for videos outside the range
  Future<void> execute({
    required List<Video> videos,
    required int currentIndex,
    String? quality,
  }) async {
    if (videos.isEmpty) return;

    final startTime = DateTime.now();

    // AC1: Preload previous 2 and next 2 videos (total 4 videos)
    final preloadStart = (currentIndex - 2).clamp(0, videos.length);
    final preloadEnd = (currentIndex + 3).clamp(0, videos.length);

    // Get videos to preload
    final videosToPreload = <Video>[];
    for (int i = preloadStart; i < preloadEnd; i++) {
      if (i != currentIndex && i >= 0 && i < videos.length) {
        videosToPreload.add(videos[i]);
      }
    }

    // Preload videos
    await _preloaderService.preloadVideos(
      videosToPreload,
      currentIndex,
      quality: quality,
    );

    // AC5: Capture preload metrics
    final latency = DateTime.now().difference(startTime).inMilliseconds;
    final queueDepth = _preloaderService.getQueueDepth();
    _performanceService?.getMetrics(); // Trigger metrics update

    // AC5: Emit Segment event feed_preload_complete with latency metadata
    _analyticsService?.trackEvent(
      FeedPreloadCompleteEvent(
        queueDepth: queueDepth,
        latencyMs: latency,
        networkType: quality, // Use quality as proxy for network type
      ),
    );

    // AC5: Emit Datadog metrics (when SDK integrated)
    // TODO: Emit Datadog gauge feed.preload.queue_depth
    // TODO: Emit Datadog counter feed.cache.evictions (from cache repository)
  }

  /// Get preloaded controller for a video
  /// AC1: Returns preloaded controller if available, null otherwise
  VideoPlayerController? getPreloadedController(String videoId) {
    return _preloaderService.getPreloadedController(videoId);
  }

  /// Release controllers for videos outside the current range
  /// AC1: Releases resources when videos are out of range
  void releaseControllersOutsideRange({
    required List<Video> currentVideos,
    required int currentIndex,
    required int rangeSize,
  }) {
    // Calculate valid range
    final rangeStart =
        (currentIndex - rangeSize).clamp(0, currentVideos.length);
    final rangeEnd =
        (currentIndex + rangeSize + 1).clamp(0, currentVideos.length);

    // Get valid video IDs
    final validVideoIds = <String>{};
    for (int i = rangeStart; i < rangeEnd; i++) {
      if (i >= 0 && i < currentVideos.length) {
        validVideoIds.add(currentVideos[i].id);
      }
    }

    // Cleanup controllers outside range
    _preloaderService.cleanupControllersOutsideRange(
      currentVideos.map((v) => v.id).toList(),
      currentIndex,
      rangeSize,
    );
  }

  /// Dispose all preloaded controllers
  void dispose() {
    _preloaderService.dispose();
  }
}
