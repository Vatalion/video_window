import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/feed_configuration.dart';

/// Cache repository for feed data
/// AC2: Local cache keeps up to 100 MB of feed data (Hive box `feed_cache`) with LRU eviction
/// and redis hydration on launch
/// PERF-003: LRU cache with size limit
/// PERF-004: Crash-safe resume with state persistence
class FeedCacheRepository {
  static const String _hiveBoxName = 'feed_cache'; // AC2: Hive box name
  static const String _cacheKeyPrefix = 'feed_cache_';
  static const String _stateKey = 'feed_state';
  static const int _maxCacheSizeMB = 100; // AC2: 100 MB limit
  static const int _maxCacheSize = 50; // Fallback item limit

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Box? _hiveBox;
  final Map<String, Video> _memoryCache = {};
  final List<String> _accessOrder = []; // LRU tracking
  int _evictionCount = 0; // AC5: Track eviction count for metrics

  /// AC2: Initialize Hive box for feed cache
  Future<void> initialize() async {
    if (_hiveBox != null) return;
    try {
      _hiveBox = await Hive.openBox(_hiveBoxName);
      // AC2: Hydrate from Redis on launch (will be called separately)
    } catch (e) {
      // Hive initialization failed, fallback to secure storage
    }
  }

  /// AC2: Hydrate cache from Redis snapshot on launch
  /// This should be called during app initialization with data from Redis
  Future<void> hydrateFromRedis(Map<String, List<Video>> redisData) async {
    await initialize();
    if (_hiveBox == null) return;

    try {
      for (final entry in redisData.entries) {
        final cursor = entry.key;
        final videos = entry.value;
        if (videos.isNotEmpty) {
          await _cacheVideosToHive(cursor, videos);
        }
      }
    } catch (e) {
      // Hydration failed, continue with empty cache
    }
  }

  /// Get cached videos for a cursor
  /// AC2: Checks Hive box first, then falls back to secure storage
  Future<List<Video>?> getCachedVideos(String cursor) async {
    await initialize();

    // Check memory cache first
    if (_memoryCache.containsKey(cursor)) {
      _updateAccessOrder(cursor);
      return [_memoryCache[cursor]!];
    }

    // AC2: Check Hive box
    if (_hiveBox != null) {
      try {
        final cached = _hiveBox!.get(cursor) as String?;
        if (cached != null) {
          final videos = (jsonDecode(cached) as List)
              .map((v) => Video.fromJson(v as Map<String, dynamic>))
              .toList();

          // Restore to memory cache
          if (videos.isNotEmpty) {
            _memoryCache[cursor] = videos.first;
            _updateAccessOrder(cursor);
          }

          return videos;
        }
      } catch (e) {
        // Cache miss or error
      }
    }

    // Fallback: Check secure storage
    try {
      final cached = await _storage.read(key: '$_cacheKeyPrefix$cursor');
      if (cached != null) {
        final videos = (jsonDecode(cached) as List)
            .map((v) => Video.fromJson(v as Map<String, dynamic>))
            .toList();

        // Restore to memory cache
        if (videos.isNotEmpty) {
          _memoryCache[cursor] = videos.first;
          _updateAccessOrder(cursor);
        }

        return videos;
      }
    } catch (e) {
      // Cache miss or error
    }

    return null;
  }

  /// Cache videos for a cursor
  /// AC2: LRU eviction when cache exceeds 100 MB limit
  Future<void> cacheVideos(String cursor, List<Video> videos) async {
    await initialize();

    // Update memory cache
    if (videos.isNotEmpty) {
      _memoryCache[cursor] = videos.first;
      _updateAccessOrder(cursor);

      // AC2: Check cache size and evict if exceeds 100 MB
      await _enforceCacheSizeLimit();

      // Cache to Hive if available
      if (_hiveBox != null) {
        await _cacheVideosToHive(cursor, videos);
      } else {
        // Fallback to secure storage
        await _cacheVideosToSecureStorage(cursor, videos);
      }
    }
  }

  /// AC2: Cache videos to Hive box
  Future<void> _cacheVideosToHive(String cursor, List<Video> videos) async {
    if (_hiveBox == null) return;
    try {
      final jsonData = jsonEncode(videos.map((v) => v.toJson()).toList());
      await _hiveBox!.put(cursor, jsonData);
    } catch (e) {
      // Cache write failed
    }
  }

  /// Fallback: Cache videos to secure storage
  Future<void> _cacheVideosToSecureStorage(
      String cursor, List<Video> videos) async {
    try {
      await _storage.write(
        key: '$_cacheKeyPrefix$cursor',
        value: jsonEncode(videos.map((v) => v.toJson()).toList()),
      );
    } catch (e) {
      // Log error but don't fail
    }
  }

  /// AC2: Enforce 100 MB cache size limit with LRU eviction
  Future<void> _enforceCacheSizeLimit() async {
    if (_hiveBox == null) {
      // Fallback: Use item count limit
      while (_accessOrder.length > _maxCacheSize) {
        final oldest = _accessOrder.removeAt(0);
        _memoryCache.remove(oldest);
        await _storage.delete(key: '$_cacheKeyPrefix$oldest');
        _evictionCount++; // AC5: Track evictions
      }
      return;
    }

    // Calculate current cache size
    int totalSizeBytes = 0;
    final entries = <String, int>{}; // cursor -> size in bytes

    for (final cursor in _accessOrder) {
      try {
        final data = _hiveBox!.get(cursor) as String?;
        if (data != null) {
          final size = utf8.encode(data).length;
          entries[cursor] = size;
          totalSizeBytes += size;
        }
      } catch (e) {
        // Skip invalid entries
      }
    }

    // AC2: Evict oldest entries until under 100 MB limit
    final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024; // 100 MB
    while (totalSizeBytes > maxSizeBytes && _accessOrder.isNotEmpty) {
      final oldest = _accessOrder.removeAt(0);
      final size = entries.remove(oldest) ?? 0;
      totalSizeBytes -= size;
      _memoryCache.remove(oldest);
      await _hiveBox!.delete(oldest);
      _evictionCount++; // AC5: Track evictions
    }
  }

  /// AC5: Get eviction count for metrics
  int getEvictionCount() => _evictionCount;

  /// AC5: Reset eviction count
  void resetEvictionCount() => _evictionCount = 0;

  /// PERF-004: Save feed state for crash-safe resume
  Future<void> saveFeedState({
    required List<String> videoIds,
    String? nextCursor,
    required bool hasMore,
  }) async {
    try {
      final state = {
        'videoIds': videoIds,
        'nextCursor': nextCursor,
        'hasMore': hasMore,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _storage.write(
        key: _stateKey,
        value: jsonEncode(state),
      );
    } catch (e) {
      // Log error but don't fail
    }
  }

  /// PERF-004: Restore feed state after crash
  Future<FeedStateRestore?> restoreFeedState() async {
    try {
      final stateJson = await _storage.read(key: _stateKey);
      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        final timestamp = DateTime.parse(state['timestamp'] as String);

        // Only restore if state is recent (within 24 hours)
        if (DateTime.now().difference(timestamp).inHours < 24) {
          return FeedStateRestore(
            videoIds: List<String>.from(state['videoIds'] as List),
            nextCursor: state['nextCursor'] as String?,
            hasMore: state['hasMore'] as bool,
          );
        }
      }
    } catch (e) {
      // State restore failed
    }
    return null;
  }

  /// Clear all cache
  /// AC2: Clears both Hive box and secure storage
  Future<void> clearCache() async {
    _memoryCache.clear();
    _accessOrder.clear();
    _evictionCount = 0;

    // AC2: Clear Hive box
    if (_hiveBox != null) {
      await _hiveBox!.clear();
    }

    // Clear secure storage
    final keys = await _storage.readAll();
    for (final key in keys.keys) {
      if (key.startsWith(_cacheKeyPrefix) || key == _stateKey) {
        await _storage.delete(key: key);
      }
    }
  }

  void _updateAccessOrder(String cursor) {
    _accessOrder.remove(cursor);
    _accessOrder.add(cursor);
  }
}

class FeedStateRestore {
  final List<String> videoIds;
  final String? nextCursor;
  final bool hasMore;

  FeedStateRestore({
    required this.videoIds,
    this.nextCursor,
    required this.hasMore,
  });
}

// Extension methods for JSON serialization (simplified)
extension VideoJson on Video {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'makerId': makerId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration.inSeconds,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'tags': tags,
      'quality': quality.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  static Video fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      makerId: json['makerId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      duration: Duration(seconds: json['duration'] as int),
      viewCount: json['viewCount'] as int,
      likeCount: json['likeCount'] as int,
      tags: List<String>.from(json['tags'] as List),
      quality: VideoQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => VideoQuality.sd,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool,
      metadata: const VideoMetadata(
        width: 1920,
        height: 1080,
        format: 'hls',
        aspectRatio: 16 / 9,
        availableQualities: [
          VideoQuality.sd,
          VideoQuality.hd,
          VideoQuality.fhd
        ],
        hasCaptions: false,
      ),
    );
  }
}
