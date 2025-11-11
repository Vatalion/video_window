import '../../data/repositories/feed_repository.dart';
import '../../data/repositories/feed_cache_repository.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/feed_configuration.dart';

/// Use case for fetching feed page
/// AC1, AC2: Pagination with caching and error handling
class FetchFeedPageUseCase {
  final FeedRepository _repository;
  final FeedCacheRepository _cacheRepository;

  FetchFeedPageUseCase({
    required FeedRepository repository,
    required FeedCacheRepository cacheRepository,
  })  : _repository = repository,
        _cacheRepository = cacheRepository;

  /// Fetch feed page with caching support
  Future<FeedPageResult> execute({
    String? userId,
    FeedAlgorithm algorithm = FeedAlgorithm.personalized,
    int limit = 20,
    String? cursor,
    List<String>? excludeVideoIds,
    List<String>? preferredTags,
    bool useCache = true,
  }) async {
    // Try cache first if cursor provided
    if (useCache && cursor != null) {
      final cached = await _cacheRepository.getCachedVideos(cursor);
      if (cached != null && cached.isNotEmpty) {
        return FeedPageResult(
          videos: cached,
          nextCursor: cursor,
          hasMore: true, // Assume more available
          feedId: 'cached',
        );
      }
    }

    try {
      // Fetch from API
      final result = await _repository.fetchFeedPage(
        userId: userId,
        algorithm: algorithm,
        limit: limit,
        cursor: cursor,
        excludeVideoIds: excludeVideoIds,
        preferredTags: preferredTags,
      );

      // Cache results
      if (result.videos.isNotEmpty && cursor != null) {
        await _cacheRepository.cacheVideos(cursor, result.videos);
      }

      return result;
    } catch (e) {
      // Try cache as fallback
      if (cursor != null) {
        final cached = await _cacheRepository.getCachedVideos(cursor);
        if (cached != null && cached.isNotEmpty) {
          return FeedPageResult(
            videos: cached,
            nextCursor: cursor,
            hasMore: false,
            feedId: 'cache_fallback',
          );
        }
      }
      rethrow;
    }
  }
}

class FeedPageResult {
  final List<Video> videos;
  final String? nextCursor;
  final bool hasMore;
  final String feedId;

  FeedPageResult({
    required this.videos,
    this.nextCursor,
    required this.hasMore,
    required this.feedId,
  });
}
