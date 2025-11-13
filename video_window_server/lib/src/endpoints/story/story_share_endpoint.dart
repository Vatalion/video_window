import 'package:serverpod/serverpod.dart';
import 'package:video_window_server/src/services/story_share_service.dart';

class StoryShareEndpoint extends Endpoint {
  // In a real app, this would be injected.
  final _storyShareService = StoryShareService();

  Future<String> generateDeepLink(Session session,
      {required String storyId, required String channel}) async {
    // AC: 6 - Rate limiting
    // This would be implemented using a Redis token bucket.
    // final userId = await session.auth.authenticatedUserId;
    // if (userId == null) {
    //   throw Exception('Authentication required.');
    // }
    // final isRateLimited = await _rateLimiter.isRateLimited(userId, 'share-story');
    // if (isRateLimited) {
    //   throw Exception('Rate limit exceeded. Please try again later.');
    // }

    // AC: 3 - Generate deep link and persist share record
    final deepLink = await _storyShareService.generateDeepLink(
      session: session,
      storyId: storyId,
      channel: channel,
    );

    // AC: 3 - Audit logging
    // log.info('Deep link generated for story $storyId by user $userId');

    return deepLink;
  }
}
