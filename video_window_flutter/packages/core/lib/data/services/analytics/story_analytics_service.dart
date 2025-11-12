class StoryAnalyticsService {
  void storySaved({
    required String storyId,
    required String makerId,
    required bool saveState,
    required String ctaSurface,
  }) {
    // In a real app, this would send an event to an analytics service like Segment or Firebase.
    print(
        'Analytics: story_saved - storyId: $storyId, makerId: $makerId, saveState: $saveState, ctaSurface: $ctaSurface');
  }

  void storyShared({
    required String storyId,
    required String channel,
    required String deepLink,
    required String utmCampaign,
    required String shareId,
  }) {
    // In a real app, this would send an event to an analytics service like Segment or Firebase.
    print(
        'Analytics: story_shared - storyId: $storyId, channel: $channel, deepLink: $deepLink, utmCampaign: $utmCampaign, shareId: $shareId');
  }
}
