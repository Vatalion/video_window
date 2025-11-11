import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/repositories/feed_repository.dart';
import '../../data/repositories/feed_cache_repository.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/feed_configuration.dart';

/// Use case for fetching feed page
/// AC1, AC2, AC5: Pagination with caching, error handling, and cursor persistence
class FetchFeedPageUseCase {
  final FeedRepository _repository;
  final FeedCacheRepository _cacheRepository;
  final FlutterSecureStorage _secureStorage;

  static const String _lastCursorKey = 'feed_last_cursor';
  static const String _lastFeedSessionIdKey = 'feed_last_session_id';

  FetchFeedPageUseCase({
    required FeedRepository repository,
    required FeedCacheRepository cacheRepository,
    FlutterSecureStorage? secureStorage,
  })  : _repository = repository,
        _cacheRepository = cacheRepository,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Fetch feed page with caching support and cursor persistence
  /// AC1: Cursor-based pagination with 20-item pages
  /// AC5: Persist last cursor for app restart recovery
  Future<FeedPageResult> execute({
    String? userId,
    FeedAlgorithm algorithm = FeedAlgorithm.personalized,
    int limit = 20,
    String? cursor,
    List<String>? excludeVideoIds,
    List<String>? preferredTags,
    bool useCache = true,
    bool restoreLastCursor = false,
  }) async {
    // AC5: Restore last cursor if requested (for app restart)
    String? effectiveCursor = cursor;
    if (restoreLastCursor && effectiveCursor == null) {
      effectiveCursor = await getLastCursor();
    }

    // Try cache first if cursor provided
    if (useCache && effectiveCursor != null) {
      final cached = await _cacheRepository.getCachedVideos(effectiveCursor);
      if (cached != null && cached.isNotEmpty) {
        return FeedPageResult(
          videos: cached,
          nextCursor: effectiveCursor,
          hasMore: true, // Assume more available
          feedId: await getLastFeedSessionId() ?? 'cached',
        );
      }
    }

    try {
      // Fetch from API
      final result = await _repository.fetchFeedPage(
        userId: userId,
        algorithm: algorithm,
        limit: limit,
        cursor: effectiveCursor,
        excludeVideoIds: excludeVideoIds,
        preferredTags: preferredTags,
      );

      // AC5: Persist cursor and feedSessionId for app restart recovery
      if (result.nextCursor != null) {
        await saveLastCursor(result.nextCursor!);
      }
      if (result.feedId.isNotEmpty && result.feedId != 'placeholder') {
        await saveLastFeedSessionId(result.feedId);
      }

      // Cache results
      if (result.videos.isNotEmpty && result.nextCursor != null) {
        await _cacheRepository.cacheVideos(result.nextCursor!, result.videos);
      }

      return result;
    } catch (e) {
      // Try cache as fallback
      if (effectiveCursor != null) {
        final cached = await _cacheRepository.getCachedVideos(effectiveCursor);
        if (cached != null && cached.isNotEmpty) {
          return FeedPageResult(
            videos: cached,
            nextCursor: effectiveCursor,
            hasMore: false,
            feedId: await getLastFeedSessionId() ?? 'cache_fallback',
          );
        }
      }
      rethrow;
    }
  }

  /// AC5: Save last cursor to secure storage
  Future<void> saveLastCursor(String cursor) async {
    try {
      await _secureStorage.write(key: _lastCursorKey, value: cursor);
    } catch (e) {
      // Log error but don't fail - cursor persistence is best-effort
    }
  }

  /// AC5: Get last cursor from secure storage
  Future<String?> getLastCursor() async {
    try {
      return await _secureStorage.read(key: _lastCursorKey);
    } catch (e) {
      return null;
    }
  }

  /// AC2: Save last feedSessionId to secure storage
  Future<void> saveLastFeedSessionId(String feedSessionId) async {
    try {
      await _secureStorage.write(
          key: _lastFeedSessionIdKey, value: feedSessionId);
    } catch (e) {
      // Log error but don't fail
    }
  }

  /// AC2: Get last feedSessionId from secure storage
  Future<String?> getLastFeedSessionId() async {
    try {
      return await _secureStorage.read(key: _lastFeedSessionIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Clear persisted cursor and session ID
  Future<void> clearPersistedState() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _lastCursorKey),
        _secureStorage.delete(key: _lastFeedSessionIdKey),
      ]);
    } catch (e) {
      // Ignore errors
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
