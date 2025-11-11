import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import 'recommendation_bridge_service.dart';

/// Feed service for feed operations
/// AC1, AC2, AC3: Feed retrieval, pagination, and personalization
/// AC1 (Story 4-5): Integrates with recommendation bridge service for personalized feeds
class FeedService {
  final Session _session;
  RecommendationBridgeService? _recommendationBridge;

  FeedService(this._session);

  RecommendationBridgeService get _recommendationService {
    _recommendationBridge ??= RecommendationBridgeService(_session);
    return _recommendationBridge!;
  }

  /// Get feed videos with pagination
  /// AC1, AC2: Cursor-based pagination with personalization and feedSessionId
  Future<FeedResult> getFeedVideos({
    String? userId,
    String algorithm = 'personalized',
    int limit = 20,
    String? cursor,
    List<String>? excludeVideoIds,
    List<String>? preferredTags,
  }) async {
    try {
      // AC2: Generate feedSessionId if not provided (for session tracking)
      final feedSessionId = _generateFeedSessionId(userId);

      // AC4: Start Datadog trace span for pagination latency (requires Datadog SDK)
      // TODO: Implement Datadog tracing when SDK integrated
      // final span = tracer.startSpan('feed.pagination', tags: {
      //   'user_id': userId ?? 'anonymous',
      //   'algorithm': algorithm,
      //   'cursor': cursor ?? 'initial',
      // });

      // Check cache first (Redis-backed cache key format: feed:page:{userId}:{cursor})
      final cacheKey = _buildCacheKey(userId, algorithm, cursor);
      final cached = await _session.caches.local.get(cacheKey);
      if (cached != null) {
        final cachedData = jsonDecode(cached as String) as Map<String, dynamic>;
        // AC4: Record cache hit in Datadog span (when SDK integrated)
        // span?.setTag('cache.hit', true);
        // span?.finish();
        return FeedResult(
          videos: List<Map<String, dynamic>>.from(cachedData['videos'] as List),
          nextCursor: cachedData['nextCursor'] as String?,
          hasMore: cachedData['hasMore'] as bool,
          feedId: cachedData['feedId'] as String? ?? feedSessionId,
        );
      }

      // AC4: Record cache miss in Datadog span (when SDK integrated)
      // span?.setTag('cache.hit', false);

      // AC1 (Story 4-5): Request recommendations from LightFM when algorithm is personalized
      // AC5: Include blocked makers from user preferences
      List<String> recommendedVideoIds = [];
      List<String>? blockedMakers;
      if (userId != null) {
        final userPrefs = await getFeedPreferences(userId);
        blockedMakers = userPrefs != null
            ? List<String>.from(userPrefs['blockedMakers'] as List? ?? [])
            : null;
      }

      if (algorithm == 'personalized' && userId != null) {
        try {
          recommendedVideoIds = await _recommendationService.getRecommendations(
            userId: userId,
            limit: limit,
            excludeVideoIds: excludeVideoIds,
            preferredTags: preferredTags,
            blockedMakers: blockedMakers, // AC5: Include blocked makers
          );
        } catch (e) {
          _session.log(
            'Failed to get recommendations, falling back to trending: $e',
            level: LogLevel.warning,
          );
          // Fallback handled by recommendation bridge service
          algorithm = 'trending';
        }
      }

      // TODO: Implement actual database queries
      // This will:
      // 1. Query stories table with filters
      // 2. Apply personalization algorithm (trending/personalized/newest)
      // 3. Use recommendedVideoIds to order results when algorithm is personalized
      // 4. Generate cursor for next page
      // 5. AC4: Filter out videos from blocked makers

      // AC4: Filter out blocked makers from videos
      // This filtering will happen in database query, but we also filter here as safety
      final filteredVideoIds = recommendedVideoIds.where((id) {
        // In real implementation, we'd check video.makerId against blockedMakers
        // For now, placeholder filtering
        return true;
      }).toList();

      // Placeholder implementation - will use recommendedVideoIds when DB queries are implemented
      final result = FeedResult(
        videos: filteredVideoIds
            .map((id) => {
                  'id': id,
                  'title': 'Video $id',
                  // TODO: Fetch full video data from database
                  // AC4: Ensure makerId is included for filtering
                })
            .toList(),
        nextCursor: filteredVideoIds.isNotEmpty
            ? 'cursor_${filteredVideoIds.last}'
            : null,
        hasMore: filteredVideoIds.length >= limit,
        feedId: feedSessionId, // AC2: Include feedSessionId
      );

      // Cache result with Redis key format: feed:page:{userId}:{cursor}
      // Note: Cache API may need adjustment based on Serverpod version
      // For now, caching is handled by Redis directly if needed

      // AC4: Finish Datadog span with latency measurement (when SDK integrated)
      // span?.setTag('cache.hit', false);
      // span?.setTag('result.count', result.videos.length);
      // span?.finish();

      return result;
    } catch (e) {
      _session.log(
        'Failed to fetch feed: $e',
        level: LogLevel.error,
      );
      rethrow;
    }
  }

  /// AC2: Generate feedSessionId for session tracking
  String _generateFeedSessionId(String? userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userPrefix = userId ?? 'anonymous';
    return 'feed_session_${userPrefix}_$timestamp';
  }

  /// AC2: Build Redis cache key: feed:page:{userId}:{cursor}
  String _buildCacheKey(String? userId, String algorithm, String? cursor) {
    final userPart = userId ?? 'anonymous';
    final cursorPart = cursor ?? 'initial';
    return 'feed:page:$userPart:$cursorPart';
  }

  /// Record video interaction
  /// AC8: Track engagement metrics
  Future<void> recordInteraction({
    required String userId,
    required String videoId,
    required String interaction,
    int? watchTime,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // TODO: Implement interaction recording
      // This will:
      // 1. Store interaction in user_interactions table
      // 2. Stream to Kafka topic feed.interactions.v1
      // 3. Update analytics

      _session.log(
        'Interaction recorded: $interaction for video $videoId',
        level: LogLevel.info,
      );
    } catch (e) {
      _session.log(
        'Failed to record interaction: $e',
        level: LogLevel.error,
      );
      rethrow;
    }
  }

  /// Update feed preferences
  /// AC1: Persists FeedConfiguration entity, storing blocked makers and quality preferences
  /// AC2: Recalculates personalization configuration and returns effective settings
  /// AC5: Updates recommendation payloads to include user-configured tags and blocked makers
  Future<Map<String, dynamic>> updateFeedPreferences({
    required String userId,
    required Map<String, dynamic> configuration,
  }) async {
    try {
      // AC1: Validate blocked makers limit (max 200)
      final blockedMakers = List<String>.from(
        configuration['blockedMakers'] as List? ?? [],
      );
      if (blockedMakers.length > 200) {
        throw Exception('Blocked makers list cannot exceed 200 entries');
      }

      // AC1: Store preferences in database
      // TODO: Implement actual database persistence when schema is ready
      // This will:
      // 1. Upsert feed_configurations table with userId as key
      // 2. Store preferredTags, blockedMakers, preferredQuality, autoPlay, showCaptions, playbackSpeed, algorithm
      // 3. Update lastUpdated timestamp

      // For now, store in session cache as placeholder
      final configKey = 'feed:config:$userId';
      // Note: Cache API requires SerializableModel, using String value directly
      // This matches the pattern used in feed_cache_manager.dart
      await _session.caches.local.put(
        configKey,
        jsonEncode(configuration) as dynamic,
      );

      // AC2: Recalculate effective settings
      final effectiveAlgorithm =
          configuration['algorithm'] as String? ?? 'personalized';
      final preferredTags = List<String>.from(
        configuration['preferredTags'] as List? ?? [],
      );

      // AC5: Update recommendation payloads to include user-configured tags and blocked makers
      // This is handled when getFeedVideos is called with these parameters

      // Return effective configuration
      return {
        'id': configuration['id'] ?? 'config_$userId',
        'userId': userId,
        'preferredTags': preferredTags,
        'blockedMakers': blockedMakers,
        'preferredQuality': configuration['preferredQuality'] ?? 'hd',
        'autoPlay': configuration['autoPlay'] ?? true,
        'showCaptions': configuration['showCaptions'] ?? false,
        'playbackSpeed': configuration['playbackSpeed'] ?? 1.0,
        'algorithm': effectiveAlgorithm,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _session.log(
        'Failed to update feed preferences: $e',
        level: LogLevel.error,
      );
      rethrow;
    }
  }

  /// Get feed preferences for a user
  Future<Map<String, dynamic>?> getFeedPreferences(String userId) async {
    try {
      final configKey = 'feed:config:$userId';
      final cached = await _session.caches.local.get(configKey);
      if (cached != null) {
        return jsonDecode(cached as String) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _session.log(
        'Failed to get feed preferences: $e',
        level: LogLevel.error,
      );
      return null;
    }
  }
}

class FeedResult {
  final List<Map<String, dynamic>> videos;
  final String? nextCursor;
  final bool hasMore;
  final String feedId;

  FeedResult({
    required this.videos,
    this.nextCursor,
    required this.hasMore,
    required this.feedId,
  });
}
