import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../lib/data/repositories/feed_cache_repository.dart';
import '../../lib/domain/entities/video.dart';

void main() {
  group('FeedCacheRepository', () {
    late FeedCacheRepository repository;

    setUp(() {
      repository = FeedCacheRepository();
    });

    test('caches videos and retrieves them', () async {
      final video = Video(
        id: 'test_video',
        makerId: 'test_maker',
        title: 'Test Video',
        description: 'Test',
        videoUrl: 'https://example.com/video.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        duration: const Duration(seconds: 60),
        viewCount: 100,
        likeCount: 50,
        tags: ['test'],
        quality: VideoQuality.hd,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        metadata: const VideoMetadata(
          width: 1920,
          height: 1080,
          format: 'hls',
          aspectRatio: 16 / 9,
          availableQualities: [VideoQuality.sd],
          hasCaptions: false,
        ),
      );

      await repository.cacheVideos('cursor1', [video]);
      final cached = await repository.getCachedVideos('cursor1');

      expect(cached, isNotNull);
      expect(cached!.length, 1);
      expect(cached.first.id, 'test_video');
    });

    test('saves and restores feed state', () async {
      await repository.saveFeedState(
        videoIds: ['video1', 'video2'],
        nextCursor: 'cursor123',
        hasMore: true,
      );

      final restored = await repository.restoreFeedState();

      expect(restored, isNotNull);
      expect(restored!.videoIds, ['video1', 'video2']);
      expect(restored.nextCursor, 'cursor123');
      expect(restored.hasMore, true);
    });
  });
}
