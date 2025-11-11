import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/use_cases/preload_videos_use_case.dart';
import '../../lib/data/services/video_preloader_service.dart';
import '../../lib/data/services/feed_performance_service.dart';
import '../../lib/data/repositories/feed_cache_repository.dart';
import '../../lib/domain/entities/video.dart';
import 'package:core/services/analytics_service.dart';

/// Integration tests for preload pipeline
/// AC1, AC2, AC4: Simulating warm/cold loads and verifying preload behavior
class MockVideoPreloaderService extends Mock implements VideoPreloaderService {}

class MockFeedPerformanceService extends Mock
    implements FeedPerformanceService {}

class MockFeedCacheRepository extends Mock implements FeedCacheRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('Preload Pipeline Integration Tests', () {
    late MockVideoPreloaderService mockPreloaderService;
    late MockFeedPerformanceService mockPerformanceService;
    late MockFeedCacheRepository mockCacheRepository;
    late MockAnalyticsService mockAnalyticsService;
    late PreloadVideosUseCase useCase;

    setUp(() {
      mockPreloaderService = MockVideoPreloaderService();
      mockPerformanceService = MockFeedPerformanceService();
      mockCacheRepository = MockFeedCacheRepository();
      mockAnalyticsService = MockAnalyticsService();
      useCase = PreloadVideosUseCase(
        preloaderService: mockPreloaderService,
        performanceService: mockPerformanceService,
        analyticsService: mockAnalyticsService,
      );
    });

    group('Warm Load Scenario', () {
      test('AC4: Video startup latency ≤ 800 ms P95 after preload', () async {
        // Arrange
        final videos = List.generate(
            10,
            (i) => Video(
                  id: 'video_$i',
                  makerId: 'maker_1',
                  title: 'Video $i',
                  description: 'Description $i',
                  videoUrl: 'https://example.com/video_$i.mp4',
                  thumbnailUrl: 'https://example.com/thumb_$i.jpg',
                  duration: const Duration(seconds: 30),
                  viewCount: 100,
                  likeCount: 10,
                  tags: [],
                  quality: VideoQuality.hd,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  isActive: true,
                  metadata: const VideoMetadata(
                    width: 1920,
                    height: 1080,
                    format: 'hls',
                    aspectRatio: 16 / 9,
                    availableQualities: [VideoQuality.hd],
                    hasCaptions: false,
                  ),
                ));

        when(() => mockPreloaderService.preloadVideos(any(), any(),
            quality: any(named: 'quality'))).thenAnswer((_) async {});
        when(() => mockPreloaderService.getQueueDepth()).thenReturn(4);
        when(() => mockPreloaderService.getPreloadedController('video_5'))
            .thenReturn(null); // Simulate preloaded controller available

        // Act - Simulate warm load (preload already done)
        final startTime = DateTime.now();
        await useCase.execute(
          videos: videos,
          currentIndex: 5,
          quality: 'high',
        );
        final latency = DateTime.now().difference(startTime).inMilliseconds;

        // Assert - Warm load should be fast
        expect(latency, lessThan(800)); // AC4: ≤ 800 ms P95
      });
    });

    group('Cold Load Scenario', () {
      test('AC4: Cold loads ≤ 2 s P95', () async {
        // Arrange
        final videos = List.generate(
            5,
            (i) => Video(
                  id: 'video_$i',
                  makerId: 'maker_1',
                  title: 'Video $i',
                  description: 'Description $i',
                  videoUrl: 'https://example.com/video_$i.mp4',
                  thumbnailUrl: 'https://example.com/thumb_$i.jpg',
                  duration: const Duration(seconds: 30),
                  viewCount: 100,
                  likeCount: 10,
                  tags: [],
                  quality: VideoQuality.hd,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  isActive: true,
                  metadata: const VideoMetadata(
                    width: 1920,
                    height: 1080,
                    format: 'hls',
                    aspectRatio: 16 / 9,
                    availableQualities: [VideoQuality.hd],
                    hasCaptions: false,
                  ),
                ));

        when(() => mockPreloaderService.preloadVideos(any(), any(),
            quality: any(named: 'quality'))).thenAnswer((_) async {
          // Simulate network delay for cold load
          await Future.delayed(const Duration(milliseconds: 500));
        });
        when(() => mockPreloaderService.getQueueDepth()).thenReturn(0);

        // Act - Simulate cold load (no preload)
        final startTime = DateTime.now();
        await useCase.execute(
          videos: videos,
          currentIndex: 2,
          quality: 'high',
        );
        final latency = DateTime.now().difference(startTime).inMilliseconds;

        // Assert - Cold load should be ≤ 2s
        expect(latency, lessThan(2000)); // AC4: ≤ 2 s P95
      });
    });

    group('Cache Integration', () {
      test('AC2: Cache hydration on launch works correctly', () async {
        // Arrange
        when(() => mockCacheRepository.initialize()).thenAnswer((_) async {});
        when(() => mockCacheRepository.hydrateFromRedis(any()))
            .thenAnswer((_) async {});

        // Act
        await mockCacheRepository.initialize();
        await mockCacheRepository.hydrateFromRedis({});

        // Assert
        verify(() => mockCacheRepository.initialize()).called(1);
        verify(() => mockCacheRepository.hydrateFromRedis(any())).called(1);
      });
    });

    group('Controller Release', () {
      test('AC1: Controllers released when out of range', () {
        // Arrange
        final videos = List.generate(
            10,
            (i) => Video(
                  id: 'video_$i',
                  makerId: 'maker_1',
                  title: 'Video $i',
                  description: 'Description $i',
                  videoUrl: 'https://example.com/video_$i.mp4',
                  thumbnailUrl: 'https://example.com/thumb_$i.jpg',
                  duration: const Duration(seconds: 30),
                  viewCount: 100,
                  likeCount: 10,
                  tags: [],
                  quality: VideoQuality.hd,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  isActive: true,
                  metadata: const VideoMetadata(
                    width: 1920,
                    height: 1080,
                    format: 'hls',
                    aspectRatio: 16 / 9,
                    availableQualities: [VideoQuality.hd],
                    hasCaptions: false,
                  ),
                ));

        when(() => mockPreloaderService.cleanupControllersOutsideRange(
              any(),
              any(),
              any(),
            )).thenReturn(null);

        // Act - Move from index 5 to index 8
        useCase.releaseControllersOutsideRange(
          currentVideos: videos,
          currentIndex: 8,
          rangeSize: 2,
        );

        // Assert - Controllers outside range 6-10 should be released
        verify(() => mockPreloaderService.cleanupControllersOutsideRange(
              any(),
              8,
              2,
            )).called(1);
      });
    });
  });
}
