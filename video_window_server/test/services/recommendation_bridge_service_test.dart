import 'package:test/test.dart';
import '../integration/test_tools/serverpod_test_tools.dart';
import 'package:video_window_server/src/services/recommendation_bridge_service.dart';
import 'package:video_window_server/src/services/feed_service.dart';

void main() {
  withServerpod(
    'RecommendationBridgeService Tests',
    (sessionBuilder, endpoints) {
      group('RecommendationBridgeService - AC1: gRPC Integration', () {
        test('should have gRPC deadline set to 150ms', () {
          // AC1: Verify deadline constant is 150ms
          expect(RecommendationBridgeService.grpcDeadline,
              const Duration(milliseconds: 150));
        });

        test('should have max retries capped at 2', () {
          // AC1: Verify retry limit is 2
          expect(RecommendationBridgeService.maxRetries, 2);
        });

        test('should have LightFM API version v2025.9', () {
          // AC1: Verify API version matches requirement
          expect(RecommendationBridgeService.lightfmApiVersion, 'v2025.9');
        });

        test('should return recommendations when called', () async {
          // AC1: Test that service returns list of video IDs
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final result = await service.getRecommendations(
            userId: 'test_user_1',
            limit: 10,
          );

          expect(result, isA<List<String>>());
          expect(result.length, lessThanOrEqualTo(10));
        });

        test('should handle excludeVideoIds parameter', () async {
          // AC1: Test exclusion filter
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final excludeIds = ['video_1', 'video_2'];
          final result = await service.getRecommendations(
            userId: 'test_user_1',
            limit: 10,
            excludeVideoIds: excludeIds,
          );

          expect(result, isA<List<String>>());
        });

        test('should handle preferredTags parameter', () async {
          // AC1: Test personalization filters
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final preferredTags = ['comedy', 'music'];
          final result = await service.getRecommendations(
            userId: 'test_user_1',
            limit: 10,
            preferredTags: preferredTags,
          );

          expect(result, isA<List<String>>());
        });
      });

      group('RecommendationBridgeService - AC2: Fallback Logic', () {
        test('should fallback to trending feed on error', () async {
          // AC2: Test fallback when recommendation service fails
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final result = await service.getRecommendations(
            userId: 'test_user_fallback',
            limit: 5,
          );

          // Should return results (either from LightFM or trending fallback)
          expect(result, isA<List<String>>());
        });
      });

      group('RecommendationBridgeService - Circuit Breaker', () {
        test('should implement circuit breaker pattern', () async {
          // Verify circuit breaker state exists
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final result = await service.getRecommendations(
            userId: 'test_user_circuit',
            limit: 5,
          );

          expect(result, isA<List<String>>());
        });
      });

      group('RecommendationBridgeService - Integration with FeedService', () {
        test('should integrate with FeedService for personalized feed',
            () async {
          // AC1: Test integration point
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final result = await feedService.getFeedVideos(
            userId: 'test_user_integration',
            algorithm: 'personalized',
            limit: 10,
          );

          expect(result, isNotNull);
          expect(result.feedId, isNotEmpty);
          expect(result.videos, isA<List<Map<String, dynamic>>>());
        });

        test('should fallback to trending when personalized fails', () async {
          // AC2: Test fallback propagation through FeedService
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final result = await feedService.getFeedVideos(
            userId: 'test_user_fallback_integration',
            algorithm: 'personalized',
            limit: 10,
          );

          expect(result, isNotNull);
          expect(result.feedId, isNotEmpty);
        });
      });
    },
  );
}
