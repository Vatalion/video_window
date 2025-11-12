import '../../../../core/lib/data/services/analytics/story_analytics_service.dart';
import '../domain/entities/share_response.dart';
import '../domain/repositories/share_repository.dart';

/// Use case to generate story deep link for sharing
/// AC3, AC5, AC6: Share functionality with deep links, analytics, and rate limiting
class GenerateStoryDeepLinkUseCase {
  final ShareRepository _shareRepository;
  final StoryAnalyticsService _analyticsService;

  GenerateStoryDeepLinkUseCase(this._shareRepository, this._analyticsService);

  Future<ShareResponse> execute({
    required String storyId,
    required String channel,
    String? customMessage,
  }) async {
    final shareResponse = await _shareRepository.generateStoryDeepLink(
      storyId: storyId,
      channel: channel,
    );

    _analyticsService.storyShared(
      storyId: storyId,
      channel: channel,
      deepLink: shareResponse.deepLink,
      utmCampaign: 'story-share', // This would be dynamic in a real app
      shareId: shareResponse.shareId,
    );

    return shareResponse;
  }
}
