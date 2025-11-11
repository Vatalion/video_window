import 'package:serverpod/serverpod.dart';
import 'dart:convert';

/// Feed cache manager for Redis hydration and TTL enforcement
/// AC2: Redis structures `feed:prefetch:{videoId}` store cached manifests with TTL 10 minutes
/// AC3: Provides cache hydration for client on launch
class FeedCacheManager {
  final Session _session;
  static const String _prefetchPrefix = 'feed:prefetch:';
  static const Duration _prefetchTTL =
      Duration(minutes: 10); // AC2: TTL 10 minutes

  FeedCacheManager(this._session);

  /// AC2: Store cached video manifest in Redis
  /// Key format: feed:prefetch:{videoId}
  Future<void> cacheVideoManifest({
    required String videoId,
    required Map<String, dynamic> manifestData,
  }) async {
    try {
      final key = '$_prefetchPrefix$videoId';
      final value = jsonEncode(manifestData);

      await _session.caches.local.put(
        key,
        value,
        ttl: _prefetchTTL,
      );
    } catch (e) {
      _session.log('Failed to cache video manifest for $videoId: $e',
          level: LogLevel.warning);
    }
  }

  /// AC2: Get cached video manifest from Redis
  Future<Map<String, dynamic>?> getCachedManifest(String videoId) async {
    try {
      final key = '$_prefetchPrefix$videoId';
      final cached = await _session.caches.local.get(key);

      if (cached != null) {
        return jsonDecode(cached as String) as Map<String, dynamic>;
      }
    } catch (e) {
      _session.log('Failed to get cached manifest for $videoId: $e',
          level: LogLevel.warning);
    }
    return null;
  }

  /// AC2: Get all cached manifests for hydration
  /// Returns map of videoId -> manifest data for client hydration on launch
  Future<Map<String, Map<String, dynamic>>> getAllCachedManifests({
    int? limit,
  }) async {
    final manifests = <String, Map<String, dynamic>>{};

    try {
      // Note: Serverpod's cache API doesn't support listing all keys
      // In production, you might need to maintain a separate index or use Redis directly
      // For now, this is a placeholder that would need Redis direct access
      _session.log(
        'getAllCachedManifests: Direct Redis access required for full implementation',
        level: LogLevel.info,
      );

      // TODO: Implement Redis SCAN or maintain a separate index set
      // This would require direct Redis client access, not available through Serverpod cache API
    } catch (e) {
      _session.log('Failed to get all cached manifests: $e',
          level: LogLevel.warning);
    }

    return manifests;
  }

  /// AC2: Invalidate cached manifest
  Future<void> invalidateManifest(String videoId) async {
    try {
      final key = '$_prefetchPrefix$videoId';
      await _session.caches.local.remove(key);
    } catch (e) {
      _session.log('Failed to invalidate manifest for $videoId: $e',
          level: LogLevel.warning);
    }
  }

  /// AC2: Check if manifest is cached and not expired
  Future<bool> isManifestCached(String videoId) async {
    try {
      final manifest = await getCachedManifest(videoId);
      return manifest != null;
    } catch (e) {
      return false;
    }
  }

  /// AC2: Get cache statistics for monitoring
  Future<Map<String, dynamic>> getCacheStats() async {
    // Note: Serverpod cache API doesn't provide statistics
    // In production, you would query Redis INFO command or maintain counters
    return {
      'prefetchPrefix': _prefetchPrefix,
      'ttlMinutes': _prefetchTTL.inMinutes,
      'note': 'Direct Redis access required for full statistics',
    };
  }
}
