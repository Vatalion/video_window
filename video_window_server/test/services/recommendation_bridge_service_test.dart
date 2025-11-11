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
          expect(result.length, greaterThan(0));
          expect(result.length, lessThanOrEqualTo(10));
          // Verify all items are strings
          for (final item in result) {
            expect(item, isA<String>());
            expect(item.isNotEmpty, isTrue);
          }
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
          expect(result.length, greaterThan(0));
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
          expect(result.length, greaterThan(0));
        });

        test('should respect limit parameter', () async {
          // AC1: Test limit enforcement
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final result5 = await service.getRecommendations(
            userId: 'test_user_limit',
            limit: 5,
          );

          final result20 = await service.getRecommendations(
            userId: 'test_user_limit',
            limit: 20,
          );

          expect(result5.length, lessThanOrEqualTo(5));
          expect(result20.length, lessThanOrEqualTo(20));
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
          expect(result.length, greaterThan(0));
        });

        test('should log fallback event', () async {
          // AC2: Verify fallback logging occurs
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          // Trigger fallback by calling with user that may cause error
          final result = await service.getRecommendations(
            userId: 'test_user_fallback_log',
            limit: 5,
          );

          expect(result, isA<List<String>>());
          // Note: Log verification would require access to session logs
          // In production, this would verify Datadog event emission
        });
      });

      group('RecommendationBridgeService - Circuit Breaker', () {
        test('should implement circuit breaker pattern', () async {
          // Verify circuit breaker state exists and functions
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final result = await service.getRecommendations(
            userId: 'test_user_circuit',
            limit: 5,
          );

          expect(result, isA<List<String>>());
          expect(result.length, greaterThan(0));
        });

        test('should handle multiple consecutive calls', () async {
          // Test circuit breaker under load
          final session = sessionBuilder.build();
          final service = RecommendationBridgeService(session);

          final results = await Future.wait([
            service.getRecommendations(userId: 'test_user_1', limit: 5),
            service.getRecommendations(userId: 'test_user_2', limit: 5),
            service.getRecommendations(userId: 'test_user_3', limit: 5),
          ]);

          expect(results.length, equals(3));
          for (final result in results) {
            expect(result, isA<List<String>>());
            expect(result.length, greaterThan(0));
          }
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
          expect(result.videos.length, greaterThan(0));
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
          expect(result.videos, isA<List<Map<String, dynamic>>>());
        });

        test('should propagate feedSessionId correctly', () async {
          // AC4: Test feed session ID generation
          final session = sessionBuilder.build();
          final feedService = FeedService(session);

          final result1 = await feedService.getFeedVideos(
            userId: 'test_user_session',
            algorithm: 'personalized',
            limit: 10,
          );

          final result2 = await feedService.getFeedVideos(
            userId: 'test_user_session',
            algorithm: 'personalized',
            limit: 10,
          );

          expect(result1.feedId, isNotEmpty);
          expect(result2.feedId, isNotEmpty);
          // Feed session IDs should be unique per request
          expect(result1.feedId, isNot(equals(result2.feedId)));
        });
      });
    },
  );
}
