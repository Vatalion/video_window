import '../../data/repositories/feed_repository.dart';
import '../../data/services/feed_analytics_events.dart';
import '../../domain/entities/video_interaction.dart';
import 'package:core/services/analytics_service.dart';

/// Use case for recording video interactions
/// AC7 (Story 4-5): Includes session + recommendation metadata in payload
class RecordInteractionUseCase {
  final FeedRepository _feedRepository;
  final AnalyticsService _analyticsService;

  RecordInteractionUseCase({
    required FeedRepository feedRepository,
    required AnalyticsService analyticsService,
  })  : _feedRepository = feedRepository,
        _analyticsService = analyticsService;

  /// Record video interaction with recommendation metadata
  /// AC7: Includes session + recommendation metadata (algorithm, feed session, experiment variant IDs)
  Future<void> call({
    required String userId,
    required String videoId,
    required InteractionType type,
    Duration? watchTime,
    String? feedSessionId,
    String? algorithm,
    String? experimentVariantId,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    // AC7: Build metadata payload with session + recommendation data
    final metadata = <String, dynamic>{
      if (feedSessionId != null) 'feedSessionId': feedSessionId,
      if (algorithm != null) 'algorithm': algorithm,
      if (experimentVariantId != null)
        'experimentVariantId': experimentVariantId,
      ...?additionalMetadata,
    };

    try {
      // Record interaction via repository (will stream to Kafka)
      await _feedRepository.recordInteraction(
        userId: userId,
        videoId: videoId,
        type: type,
        watchTime: watchTime,
        metadata: metadata.isNotEmpty ? metadata : null,
      );

      // AC4: Emit Segment analytics event with recommendation metadata
      // AC6: Analytics instrumentation for recommendation served/consumed events
      await _analyticsService.track(
        FeedRecommendationServedEvent(
          videoId: videoId,
          algorithm: algorithm ?? 'unknown',
          feedSessionId: feedSessionId ?? 'unknown',
          experimentVariantId: experimentVariantId,
        ),
      );
    } catch (e) {
      // Log error but don't fail the interaction
      _analyticsService.track(
        FeedRecommendationErrorEvent(
          videoId: videoId,
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }
}
