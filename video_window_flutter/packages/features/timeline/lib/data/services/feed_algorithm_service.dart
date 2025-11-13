import '../../domain/entities/feed_configuration.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_interaction.dart'
    show VideoInteraction, InteractionType;

/// Feed algorithm service for personalization and content ordering
/// AC3: Feed algorithm implementation with content personalization
class FeedAlgorithmService {
  /// Get personalized feed based on user interactions
  /// AC3: Content personalization based on engagement tracking
  Future<List<Video>> getPersonalizedFeed({
    required List<Video> availableVideos,
    required List<VideoInteraction> userInteractions,
    required FeedConfiguration configuration,
    int limit = 20,
  }) async {
    // Calculate engagement scores for each video
    final videoScores = <String, double>{};

    for (final video in availableVideos) {
      double score = 0.0;

      // Base score from video metrics
      score += video.viewCount * 0.1;
      score += video.likeCount * 0.5;

      // Personalization based on user interactions
      final userInteractionsForVideo =
          userInteractions.where((i) => i.videoId == video.id).toList();

      for (final interaction in userInteractionsForVideo) {
        switch (interaction.type) {
          case InteractionType.like:
            score += 10.0;
            break;
          case InteractionType.complete:
            score += 15.0;
            break;
          case InteractionType.share:
            score += 12.0;
            break;
          case InteractionType.follow:
            score += 8.0;
            break;
          case InteractionType.view:
            score += 1.0;
            break;
          case InteractionType.skip:
            score -= 5.0;
            break;
          case InteractionType.comment:
            score += 7.0;
            break;
        }
      }

      // Tag preference matching
      if (configuration.preferredTags.isNotEmpty) {
        final matchingTags = video.tags
            .where((tag) => configuration.preferredTags.contains(tag))
            .length;
        score += matchingTags * 3.0;
      }

      // Blocked makers penalty
      if (configuration.blockedMakers.contains(video.makerId)) {
        score = -1000.0; // Effectively remove from feed
      }

      videoScores[video.id] = score;
    }

    // Sort by score and return top N
    final sortedVideos = availableVideos.toList()
      ..sort((a, b) {
        final scoreA = videoScores[a.id] ?? 0.0;
        final scoreB = videoScores[b.id] ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

    return sortedVideos.take(limit).toList();
  }

  /// Get trending feed based on recent engagement
  Future<List<Video>> getTrendingFeed({
    required List<Video> availableVideos,
    Duration timeWindow = const Duration(hours: 24),
    int limit = 20,
  }) async {
    final cutoffTime = DateTime.now().subtract(timeWindow);

    final trendingVideos = availableVideos
        .where((video) => video.createdAt.isAfter(cutoffTime))
        .toList()
      ..sort((a, b) {
        // Sort by engagement rate (likes + views)
        final engagementA = a.likeCount + a.viewCount;
        final engagementB = b.likeCount + b.viewCount;
        return engagementB.compareTo(engagementA);
      });

    return trendingVideos.take(limit).toList();
  }

  /// Get newest feed (chronological)
  Future<List<Video>> getNewestFeed({
    required List<Video> availableVideos,
    int limit = 20,
  }) async {
    final sortedVideos = availableVideos.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sortedVideos.take(limit).toList();
  }

  /// Get feed based on algorithm selection
  Future<List<Video>> getFeedByAlgorithm({
    required FeedAlgorithm algorithm,
    required List<Video> availableVideos,
    List<VideoInteraction> userInteractions = const [],
    FeedConfiguration? configuration,
    int limit = 20,
  }) async {
    switch (algorithm) {
      case FeedAlgorithm.personalized:
        return getPersonalizedFeed(
          availableVideos: availableVideos,
          userInteractions: userInteractions,
          configuration: configuration ??
              FeedConfiguration(
                id: '',
                userId: '',
                preferredTags: const [],
                blockedMakers: const [],
                preferredQuality: VideoQuality.hd,
                autoPlay: true,
                showCaptions: false,
                playbackSpeed: 1.0,
                algorithm: FeedAlgorithm.personalized,
                lastUpdated: DateTime.now(),
              ),
          limit: limit,
        );
      case FeedAlgorithm.trending:
        return getTrendingFeed(
          availableVideos: availableVideos,
          limit: limit,
        );
      case FeedAlgorithm.newest:
        return getNewestFeed(
          availableVideos: availableVideos,
          limit: limit,
        );
      case FeedAlgorithm.following:
        // For following feed, filter by followed makers
        // This requires additional data not available in current scope
        return getNewestFeed(
          availableVideos: availableVideos,
          limit: limit,
        );
    }
  }
}
