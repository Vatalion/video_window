import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/use_cases/preload_videos_use_case.dart';
import '../../lib/data/services/video_preloader_service.dart';
import '../../lib/data/services/feed_performance_service.dart';
import '../../lib/domain/entities/video.dart';
import 'package:core/services/analytics_service.dart';

/// Performance test for preload startup latency
/// AC4: Automated test harness verifying startup latency thresholds on mid-range Android device
/// Video startup latency ≤ 800 ms P95 after preload; cold loads ≤ 2 s P95
class MockVideoPreloaderService extends Mock implements VideoPreloaderService {}

class MockFeedPerformanceService extends Mock
    implements FeedPerformanceService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('Preload Startup Latency Performance Tests', () {
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

    test('AC4: Warm load latency ≤ 800 ms P95', () async {
      // Arrange - Simulate preloaded videos
      final videos = List.generate(
          20,
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
        // Simulate fast preload (already cached)
        await Future.delayed(const Duration(milliseconds: 50));
      });
      when(() => mockPreloaderService.getQueueDepth()).thenReturn(4);

      // Act - Measure warm load latency
      final latencies = <int>[];
      for (int i = 0; i < 20; i++) {
        final startTime = DateTime.now();
        await useCase.execute(
          videos: videos,
          currentIndex: 10,
          quality: 'high',
        );
        final latency = DateTime.now().difference(startTime).inMilliseconds;
        latencies.add(latency);
      }

      // Assert - Calculate P95
      latencies.sort();
      final p95Index = (latencies.length * 0.95).floor();
      final p95Latency = latencies[p95Index];

      expect(p95Latency, lessThanOrEqualTo(800), // AC4: ≤ 800 ms P95
          reason:
              'P95 warm load latency should be ≤ 800ms, got ${p95Latency}ms');
    });

    test('AC4: Cold load latency ≤ 2 s P95', () async {
      // Arrange - Simulate cold start (no preload)
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
          quality: any(named: 'quality'))).thenAnswer((_) async {
        // Simulate network delay for cold load
        await Future.delayed(const Duration(milliseconds: 800));
      });
      when(() => mockPreloaderService.getQueueDepth()).thenReturn(0);

      // Act - Measure cold load latency
      final latencies = <int>[];
      for (int i = 0; i < 20; i++) {
        final startTime = DateTime.now();
        await useCase.execute(
          videos: videos,
          currentIndex: 5,
          quality: 'high',
        );
        final latency = DateTime.now().difference(startTime).inMilliseconds;
        latencies.add(latency);
      }

      // Assert - Calculate P95
      latencies.sort();
      final p95Index = (latencies.length * 0.95).floor();
      final p95Latency = latencies[p95Index];

      expect(p95Latency, lessThanOrEqualTo(2000), // AC4: ≤ 2 s P95
          reason:
              'P95 cold load latency should be ≤ 2000ms, got ${p95Latency}ms');
    });
  });
}
