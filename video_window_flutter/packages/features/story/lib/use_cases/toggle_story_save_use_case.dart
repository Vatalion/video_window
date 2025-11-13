import 'package:core/data/services/analytics/story_analytics_service.dart';
import 'package:core/domain/repositories/share_repository.dart';

/// Use case to toggle story save/wishlist state
/// AC1, AC5: Social engagement features, wishlist persistence
class ToggleStorySaveUseCase {
  final ShareRepository _shareRepository;
  final StoryAnalyticsService _analyticsService;

  ToggleStorySaveUseCase(this._shareRepository, this._analyticsService);

  Future<String?> execute({
    required String storyId,
    required String makerId,
    required bool saveState,
    required String ctaSurface,
  }) async {
    final wishlistId = await _shareRepository.toggleStorySave(
      storyId: storyId,
      isSaved: saveState,
    );

    _analyticsService.storySaved(
      storyId: storyId,
      makerId: makerId,
      saveState: saveState,
      ctaSurface: ctaSurface,
    );

    return wishlistId;
  }
}
