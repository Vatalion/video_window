import 'package:core/services/analytics_service.dart';

/// Analytics event for caption toggle
/// AC7: story_caption_toggled event with required attributes
class StoryCaptionToggledEvent extends AnalyticsEvent {
  final String storyId;
  final String language;
  final bool wasEnabled;
  final String? userAccessibilityProfile;
  final DateTime _timestamp;

  StoryCaptionToggledEvent({
    required this.storyId,
    required this.language,
    required this.wasEnabled,
    this.userAccessibilityProfile,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'story_caption_toggled';

  @override
  Map<String, dynamic> get properties => {
        'storyId': storyId,
        'language': language,
        'wasEnabled': wasEnabled,
        if (userAccessibilityProfile != null)
          'userAccessibilityProfile': userAccessibilityProfile,
      };

  @override
  DateTime get timestamp => _timestamp;
}

/// Analytics event for transcript viewed
/// AC7: story_transcript_viewed event with required attributes
class StoryTranscriptViewedEvent extends AnalyticsEvent {
  final String storyId;
  final String language;
  final String? searchTerm;
  final String? userAccessibilityProfile;
  final DateTime _timestamp;

  StoryTranscriptViewedEvent({
    required this.storyId,
    required this.language,
    this.searchTerm,
    this.userAccessibilityProfile,
  }) : _timestamp = DateTime.now();

  @override
  String get name => 'story_transcript_viewed';

  @override
  Map<String, dynamic> get properties => {
        'storyId': storyId,
        'language': language,
        if (searchTerm != null) 'searchTerm': searchTerm,
        if (userAccessibilityProfile != null)
          'userAccessibilityProfile': userAccessibilityProfile,
      };

  @override
  DateTime get timestamp => _timestamp;
}
