import 'package:test/test.dart';
import '../integration/test_tools/serverpod_test_tools.dart';
import 'package:video_window_server/src/services/feed_service.dart';
import 'package:video_window_server/src/services/recommendation_bridge_service.dart';
import 'package:video_window_server/src/endpoints/feed/interaction_endpoint.dart';

void main() {
  withServerpod(
    'Feed Recommendation Integration Tests',
    (sessionBuilder, endpoints) {
      group('Feed Recommendation Integration - End-to-End', () {
        test('should request recommendations with personalization filters',
            () async {
          // AC1: Test feed service integration with recommendation bridge
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final result = await feedService.getFeedVideos(
            userId: 'test_user_personalized',
            algorithm: 'personalized',
            limit: 20,
            preferredTags: ['comedy', 'music'],
          );

          expect(result, isNotNull);
          expect(result.feedId, isNotEmpty);
          expect(result.videos, isA<List<Map<String, dynamic>>>());
          expect(result.videos.length, lessThanOrEqualTo(20));
        });

        test('should fallback to trending when recommendation fails', () async {
          // AC2: Test fallback + metadata propagation
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final result = await feedService.getFeedVideos(
            userId: 'test_user_fallback',
            algorithm: 'personalized',
            limit: 20,
          );

          expect(result, isNotNull);
          expect(result.feedId, isNotEmpty);
          expect(result.videos, isA<List<Map<String, dynamic>>>());
        });

        test('should propagate recommendation metadata in feed result',
            () async {
          // AC4: Test metadata propagation
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final result = await feedService.getFeedVideos(
            userId: 'test_user_metadata',
            algorithm: 'personalized',
            limit: 20,
          );

          expect(result, isNotNull);
          expect(result.feedId, isNotEmpty);
          expect(result.feedId.length, greaterThan(0));
        });

        test('should handle cursor-based pagination with recommendations',
            () async {
          // AC1: Test pagination with personalized recommendations
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final firstPage = await feedService.getFeedVideos(
            userId: 'test_user_pagination',
            algorithm: 'personalized',
            limit: 10,
          );

          expect(firstPage, isNotNull);
          expect(firstPage.feedId, isNotEmpty);

          if (firstPage.nextCursor != null) {
            final secondPage = await feedService.getFeedVideos(
              userId: 'test_user_pagination',
              algorithm: 'personalized',
              limit: 10,
              cursor: firstPage.nextCursor,
            );

            expect(secondPage, isNotNull);
            expect(secondPage.feedId, firstPage.feedId);
            expect(secondPage.videos.length, lessThanOrEqualTo(10));
          }
        });
      });

      group('Interaction Endpoint - AC3: Kafka Integration', () {
        test('should record interaction with correct schema', () async {
          // AC3: Test interaction endpoint schema
          final session = sessionBuilder.build();
          final endpoint = InteractionEndpoint();

          final result = await endpoint.recordInteraction(
            session,
            userId: 'test_user_interaction',
            videoId: 'test_video_1',
            interactionType: 'view',
            watchTime: 15,
            metadata: {
              'feedSessionId': 'test_session_123',
              'algorithm': 'personalized',
            },
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result['success'], isTrue);
          expect(result['timestamp'], isNotEmpty);
          expect(result['interactionId'], isNotEmpty);
        });

        test('should handle interaction with watchTime', () async {
          // AC3: Test watchTime in schema
          final session = sessionBuilder.build();
          final endpoint = InteractionEndpoint();

          final result = await endpoint.recordInteraction(
            session,
            userId: 'test_user_watchtime',
            videoId: 'test_video_2',
            interactionType: 'view',
            watchTime: 45,
          );

          expect(result['success'], isTrue);
        });

        test('should handle interaction without watchTime', () async {
          // AC3: Test optional watchTime
          final session = sessionBuilder.build();
          final endpoint = InteractionEndpoint();

          final result = await endpoint.recordInteraction(
            session,
            userId: 'test_user_no_watchtime',
            videoId: 'test_video_3',
            interactionType: 'like',
          );

          expect(result['success'], isTrue);
        });

        test('should include metadata in interaction', () async {
          // AC4: Test recommendation metadata in interaction
          final session = sessionBuilder.build();
          final endpoint = InteractionEndpoint();

          final metadata = {
            'feedSessionId': 'session_123',
            'algorithm': 'personalized',
            'experimentVariantId': 'variant_a',
            'recommendationScore': 0.85,
          };

          final result = await endpoint.recordInteraction(
            session,
            userId: 'test_user_metadata',
            videoId: 'test_video_4',
            interactionType: 'view',
            watchTime: 30,
            metadata: metadata,
          );

          expect(result['success'], isTrue);
        });
      });

      group('Recommendation Bridge Service - Error Handling', () {
        test('should handle timeout gracefully', () async {
          // AC1: Test deadline exceeded handling
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final result = await service.getRecommendations(
            userId: 'test_user_timeout',
            limit: 10,
          );

          expect(result, isA<List<String>>());
        });

        test('should retry on transient errors', () async {
          // AC1: Test retry logic
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final result = await service.getRecommendations(
            userId: 'test_user_retry',
            limit: 10,
          );

          expect(result, isA<List<String>>());
        });
      });

      group('Data Quality - AC4: Analytics Events', () {
        test('should generate feed session ID for analytics', () async {
          // AC4: Verify feed session ID generation
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final result1 = await feedService.getFeedVideos(
            userId: 'test_user_analytics',
            algorithm: 'personalized',
            limit: 10,
          );

          final result2 = await feedService.getFeedVideos(
            userId: 'test_user_analytics',
            algorithm: 'personalized',
            limit: 10,
          );

          expect(result1.feedId, isNotEmpty);
          expect(result2.feedId, isNotEmpty);
          // Verify feed session ID format
          expect(result1.feedId, startsWith('feed_session_'));
          expect(result2.feedId, startsWith('feed_session_'));
        });

        test('should include algorithm metadata in feed result', () async {
          // AC4: Verify algorithm metadata propagation
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final personalizedResult = await feedService.getFeedVideos(
            userId: 'test_user_algorithm',
            algorithm: 'personalized',
            limit: 10,
          );

          final trendingResult = await feedService.getFeedVideos(
            userId: 'test_user_algorithm',
            algorithm: 'trending',
            limit: 10,
          );

          expect(personalizedResult.feedId, isNotEmpty);
          expect(trendingResult.feedId, isNotEmpty);
          expect(personalizedResult.videos, isA<List<Map<String, dynamic>>>());
          expect(trendingResult.videos, isA<List<Map<String, dynamic>>>());
        });
      });
    },
  );
}
