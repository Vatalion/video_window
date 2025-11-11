import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/feed_configuration.dart';

/// Cache repository for feed data
/// PERF-003: LRU cache with 50-item limit
/// PERF-004: Crash-safe resume with state persistence
class FeedCacheRepository {
  static const String _cacheKeyPrefix = 'feed_cache_';
  static const String _stateKey = 'feed_state';
  static const int _maxCacheSize = 50;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<String, Video> _memoryCache = {};
  final List<String> _accessOrder = []; // LRU tracking

  /// Get cached videos for a cursor
  Future<List<Video>?> getCachedVideos(String cursor) async {
    // Check memory cache first
    if (_memoryCache.containsKey(cursor)) {
      _updateAccessOrder(cursor);
      return [_memoryCache[cursor]!];
    }

    // Check persistent storage
    try {
      final cached = await _storage.read(key: '$_cacheKeyPrefix$cursor');
      if (cached != null) {
        final videos = (jsonDecode(cached) as List)
            .map((v) => Video.fromJson(v as Map<String, dynamic>))
            .toList();

        // Restore to memory cache
        for (final video in videos) {
          _memoryCache[cursor] = video;
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
  /// PERF-003: LRU eviction when cache exceeds limit
  Future<void> cacheVideos(String cursor, List<Video> videos) async {
    // Update memory cache
    if (videos.isNotEmpty) {
      _memoryCache[cursor] = videos.first;
      _updateAccessOrder(cursor);

      // PERF-003: Evict oldest items if cache exceeds limit
      while (_accessOrder.length > _maxCacheSize) {
        final oldest = _accessOrder.removeAt(0);
        _memoryCache.remove(oldest);
        await _storage.delete(key: '$_cacheKeyPrefix$oldest');
      }
    }

    // Persist to secure storage
    try {
      await _storage.write(
        key: '$_cacheKeyPrefix$cursor',
        value: jsonEncode(videos.map((v) => v.toJson()).toList()),
      );
    } catch (e) {
      // Log error but don't fail
    }
  }

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
  Future<void> clearCache() async {
    _memoryCache.clear();
    _accessOrder.clear();

    // Clear persistent storage
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
