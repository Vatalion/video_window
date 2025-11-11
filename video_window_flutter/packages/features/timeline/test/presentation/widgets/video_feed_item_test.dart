import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../lib/domain/entities/video.dart';
import '../../lib/domain/entities/video_interaction.dart';
import '../../lib/presentation/widgets/video_feed_item.dart';

void main() {
  group('VideoFeedItem', () {
    testWidgets('renders video player and overlay controls', (tester) async {
      final video = Video(
        id: 'test_video',
        makerId: 'test_maker',
        title: 'Test Video',
        description: 'Test Description',
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
          availableQualities: [VideoQuality.sd, VideoQuality.hd],
          hasCaptions: false,
        ),
      );

      bool visibilityChanged = false;
      InteractionType? lastInteraction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: VideoFeedItem(
                video: video,
                isPlaying: false,
                onVisibilityChanged: (isVisible, percentage) {
                  visibilityChanged = true;
                },
                onInteraction: (type, watchTime, metadata) {
                  lastInteraction = type;
                },
              ),
            ),
          ),
        ),
      );

      // Verify video player is rendered
      expect(find.byType(VideoFeedItem), findsOneWidget);

      // Verify overlay controls are present
      expect(find.text('Test Video'), findsOneWidget);
      expect(find.text('@test_maker'), findsOneWidget);
    });
  });
}
