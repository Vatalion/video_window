import 'package:serverpod/serverpod.dart';

import '../../services/feed_service.dart';
import 'interaction_endpoint.dart';

/// Feed endpoint for video feed operations
/// AC1, AC2: Feed pagination and video retrieval
class FeedEndpoint extends Endpoint {
  @override
  String get name => 'feed';

  /// Get feed videos with pagination
  /// AC1, AC2: Cursor-based pagination with max page size enforcement
  Future<Map<String, dynamic>> getFeedVideos(
    Session session, {
    String? userId,
    String algorithm = 'personalized',
    int limit = 20,
    String? cursor,
    List<String>? excludeVideoIds,
    List<String>? preferredTags,
  }) async {
    try {
      // AC2: Enforce max page size <= 50
      final effectiveLimit = limit > 50 ? 50 : limit;

      final feedService = FeedService(session);
      final result = await feedService.getFeedVideos(
        userId: userId,
        algorithm: algorithm,
        limit: effectiveLimit,
        cursor: cursor,
        excludeVideoIds: excludeVideoIds,
        preferredTags: preferredTags,
      );

      // AC2: Ensure feedSessionId is included (feedId)
      return {
        'videos': result.videos,
        'nextCursor': result.nextCursor,
        'hasMore': result.hasMore,
        'feedSessionId': result.feedId, // AC2: Return as feedSessionId
        'feedId': result.feedId, // Keep for backward compatibility
      };
    } catch (e) {
      session.log(
        'Failed to fetch feed: $e',
        level: LogLevel.error,
      );
      throw Exception('Failed to fetch feed: $e');
    }
  }

  /// Record video interaction
  /// AC3 (Story 4-5): Delegates to interaction endpoint for Kafka streaming
  /// AC8: Track engagement metrics
  Future<Map<String, dynamic>> recordInteraction(
    Session session, {
    required String userId,
    required String videoId,
    required String interaction,
    int? watchTime,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // AC3: Use interaction endpoint for Kafka streaming
      final interactionEndpoint = InteractionEndpoint();
      return await interactionEndpoint.recordInteraction(
        session,
        userId: userId,
        videoId: videoId,
        interactionType: interaction,
        watchTime: watchTime,
        metadata: metadata,
      );
    } catch (e) {
      session.log(
        'Failed to record interaction: $e',
        level: LogLevel.error,
      );
      throw Exception('Failed to record interaction: $e');
    }
  }

  /// Update feed preferences
  Future<Map<String, dynamic>> updatePreferences(
    Session session, {
    required String userId,
    required Map<String, dynamic> configuration,
  }) async {
    try {
      // TODO: Implement preference updates
      // Will:
      // 1. Store preferences in database
      // 2. Invalidate recommendation cache

      return {
        'success': true,
      };
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }
}
