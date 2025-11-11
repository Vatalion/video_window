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
