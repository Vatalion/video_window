import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';
import 'package:timeline/use_cases/preload_videos_use_case.dart';
import 'package:timeline/data/services/video_preloader_service.dart';
import 'package:timeline/data/services/feed_performance_service.dart';
import 'package:timeline/domain/entities/video.dart';
import 'package:core/services/analytics_service.dart';

// Mocks
class MockVideoPreloaderService extends Mock implements VideoPreloaderService {}

class MockFeedPerformanceService extends Mock
    implements FeedPerformanceService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('PreloadVideosUseCase', () {
    late MockVideoPreloaderService mockPreloaderService;
    late MockFeedPerformanceService mockPerformanceService;
    late MockAnalyticsService mockAnalyticsService;
    late PreloadVideosUseCase useCase;

    setUp(() {
      mockPreloaderService = MockVideoPreloaderService();
      mockPerformanceService = MockFeedPerformanceService();
      mockAnalyticsService = MockAnalyticsService();
      useCase = PreloadVideosUseCase(
        preloaderService: mockPreloaderService,
        performanceService: mockPerformanceService,
        analyticsService: mockAnalyticsService,
      );
    });

    test('should preload videos around current index (AC1)', () async {
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

      // Act
      await useCase.execute(
        videos: videos,
        currentIndex: 5,
        quality: 'high',
      );

      // Assert
      verify(() => mockPreloaderService.preloadVideos(
            any(that: predicate((List<Video> v) => v.length <= 4)),
            5,
            quality: 'high',
          )).called(1);
    });

    test('should release controllers outside range (AC1)', () {
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

      // Act
      useCase.releaseControllersOutsideRange(
        currentVideos: videos,
        currentIndex: 5,
        rangeSize: 2,
      );

      // Assert
      verify(() => mockPreloaderService.cleanupControllersOutsideRange(
            any(that: predicate((List<String> ids) => ids.length == 10)),
            5,
            2,
          )).called(1);
    });

    test('should emit metrics and analytics events (AC5)', () async {
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
          quality: any(named: 'quality'))).thenAnswer((_) async {});
      when(() => mockPreloaderService.getQueueDepth()).thenReturn(3);
      when(() => mockPerformanceService.getMetrics()).thenReturn({
        'fps': 60.0,
        'jankPercentage': 1.5,
      });
      when(() => mockAnalyticsService.trackEvent(any()))
          .thenAnswer((_) async {});

      // Act
      await useCase.execute(
        videos: videos,
        currentIndex: 2,
        quality: 'high',
      );

      // Assert
      verify(() => mockPerformanceService.getMetrics()).called(1);
      verify(() => mockAnalyticsService.trackEvent(any())).called(1);
    });

    test('should return preloaded controller if available (AC1)', () {
      // Arrange
      final mockController = MockVideoPlayerController();
      when(() => mockPreloaderService.getPreloadedController('video_1'))
          .thenReturn(mockController);

      // Act
      final controller = useCase.getPreloadedController('video_1');

      // Assert
      expect(controller, equals(mockController));
      verify(() => mockPreloaderService.getPreloadedController('video_1'))
          .called(1);
    });

    test('should handle empty video list gracefully', () async {
      // Arrange
      when(() => mockPreloaderService.preloadVideos(any(), any(),
          quality: any(named: 'quality'))).thenAnswer((_) async {});

      // Act
      await useCase.execute(
        videos: [],
        currentIndex: 0,
      );

      // Assert
      verifyNever(() => mockPreloaderService.preloadVideos(any(), any(),
          quality: any(named: 'quality')));
    });

    test('should dispose preloader service on dispose', () {
      // Arrange
      when(() => mockPreloaderService.dispose()).thenReturn(null);

      // Act
      useCase.dispose();

      // Assert
      verify(() => mockPreloaderService.dispose()).called(1);
    });
  });
}

// Mock VideoPlayerController
class MockVideoPlayerController extends Mock implements VideoPlayerController {}
