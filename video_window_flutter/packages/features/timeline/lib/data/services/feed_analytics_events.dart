import 'package:core/services/analytics_service.dart';

/// Feed video viewed event
/// AC8: Track impression events
class FeedVideoViewedEvent extends AnalyticsEvent {
  final String videoId;
  final String feedId;
  final int position;

  FeedVideoViewedEvent({
    required this.videoId,
    required this.feedId,
    required this.position,
  });

  @override
  String get name => 'feed_video_viewed';

  @override
  Map<String, dynamic> get properties => {
        'video_id': videoId,
        'feed_id': feedId,
        'position': position,
      };

  @override
  DateTime get timestamp => DateTime.now();
}

/// Feed swipe event
class FeedSwipeEvent extends AnalyticsEvent {
  final String direction;
  final String videoId;

  FeedSwipeEvent({
    required this.direction,
    required this.videoId,
  });

  @override
  String get name => 'feed_swipe';

  @override
  Map<String, dynamic> get properties => {
        'direction': direction,
        'video_id': videoId,
      };

  @override
  DateTime get timestamp => DateTime.now();
}

/// Feed like event
class FeedLikeEvent extends AnalyticsEvent {
  final String videoId;

  FeedLikeEvent({required this.videoId});

  @override
  String get name => 'feed_like';

  @override
  Map<String, dynamic> get properties => {
        'video_id': videoId,
      };

  @override
  DateTime get timestamp => DateTime.now();
}

/// Feed page loaded event
/// AC8: Track pagination events with cursor metadata and latency
class FeedPageLoadedEvent extends AnalyticsEvent {
  final String? cursor;
  final int loadTimeMs;
  final bool cacheHit;

  FeedPageLoadedEvent({
    this.cursor,
    required this.loadTimeMs,
    required this.cacheHit,
  });

  @override
  String get name => 'feed_page_loaded';

  @override
  Map<String, dynamic> get properties => {
        if (cursor != null) 'cursor': cursor,
        'load_time_ms': loadTimeMs,
        'cache_hit': cacheHit,
        'latency_bucket': _getLatencyBucket(loadTimeMs),
      };

  @override
  DateTime get timestamp => DateTime.now();

  String _getLatencyBucket(int ms) {
    if (ms < 200) return 'fast';
    if (ms < 500) return 'normal';
    if (ms < 1000) return 'slow';
    return 'very_slow';
  }
}

/// Feed pagination retry event
/// AC3: Track retry attempts for pagination failures
class FeedPaginationRetryEvent extends AnalyticsEvent {
  final String? cursor;
  final int attempt;

  FeedPaginationRetryEvent({
    this.cursor,
    required this.attempt,
  });

  @override
  String get name => 'feed_pagination_retry';

  @override
  Map<String, dynamic> get properties => {
        if (cursor != null) 'cursor': cursor,
        'attempt': attempt,
      };

  @override
  DateTime get timestamp => DateTime.now();
}

/// Feed preload complete event
/// AC5: Track preload completion with latency metadata
class FeedPreloadCompleteEvent extends AnalyticsEvent {
  final int queueDepth;
  final int latencyMs;
  final String? networkType;

  FeedPreloadCompleteEvent({
    required this.queueDepth,
    required this.latencyMs,
    this.networkType,
  });

  @override
  String get name => 'feed_preload_complete';

  @override
  Map<String, dynamic> get properties => {
        'queue_depth': queueDepth,
        'latency_ms': latencyMs,
        if (networkType != null) 'network_type': networkType,
      };

  @override
  DateTime get timestamp => DateTime.now();
}
