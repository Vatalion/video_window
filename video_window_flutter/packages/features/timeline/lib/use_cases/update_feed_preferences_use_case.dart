import '../../domain/entities/feed_configuration.dart';
import '../../domain/entities/video.dart';
import '../../data/repositories/feed_repository.dart';
import '../../data/services/feed_analytics_events.dart';
import 'package:core/services/analytics_service.dart'
    show AnalyticsService, AnalyticsEvent;

/// Use case for updating feed preferences
/// AC1: Maps form values to domain objects and calls repository
/// AC5: Emits Segment + Datadog events for preference updates
/// AC7: Ensures accessibility toggles recorded for WCAG reporting
class UpdateFeedPreferencesUseCase {
  final FeedRepository repository;
  final AnalyticsService? analyticsService;
  final FeedConfiguration? previousConfiguration;

  UpdateFeedPreferencesUseCase({
    required this.repository,
    this.analyticsService,
    this.previousConfiguration,
  });

  /// Execute preference update
  /// Returns updated configuration with effective settings
  Future<FeedConfiguration> execute({
    required String userId,
    required FeedConfiguration configuration,
  }) async {
    // Validate configuration
    if (configuration.blockedMakers.length > 200) {
      throw Exception('Blocked makers list cannot exceed 200 entries');
    }

    // Calculate diff for analytics (AC5)
    final changedFields = _calculateChangedFields(
      previousConfiguration,
      configuration,
    );

    // Update preferences via repository
    await repository.updatePreferences(
      userId: userId,
      configuration: configuration,
    );

    // AC5: Emit analytics event feed_preferences_updated
    if (analyticsService != null) {
      final event = FeedPreferencesUpdatedEvent(
        userId: userId,
        changedFields: changedFields,
        autoPlayEnabled: configuration.autoPlay,
        reducedMotion: !configuration.autoPlay &&
            configuration.preferredQuality == VideoQuality.sd,
        algorithm: configuration.algorithm.name,
        sessionId: _generateSessionId(),
      );
      await analyticsService!.trackEvent(event);
    }

    // AC7: Record accessibility toggles for WCAG reporting
    if (analyticsService != null &&
        (changedFields.contains('showCaptions') ||
            changedFields.contains('autoPlay'))) {
      final accessibilityEvent = FeedAccessibilityToggledEvent(
        userId: userId,
        showCaptions: configuration.showCaptions,
        reducedMotion: !configuration.autoPlay &&
            configuration.preferredQuality == VideoQuality.sd,
      );
      await analyticsService!.trackEvent(accessibilityEvent);
    }

    // Return updated configuration
    return FeedConfiguration(
      id: configuration.id,
      userId: userId,
      preferredTags: configuration.preferredTags,
      blockedMakers: configuration.blockedMakers,
      preferredQuality: configuration.preferredQuality,
      autoPlay: configuration.autoPlay,
      showCaptions: configuration.showCaptions,
      playbackSpeed: configuration.playbackSpeed,
      algorithm: configuration.algorithm,
      lastUpdated: DateTime.now(),
    );
  }

  List<String> _calculateChangedFields(
    FeedConfiguration? previous,
    FeedConfiguration current,
  ) {
    if (previous == null) {
      return [
        'autoPlay',
        'showCaptions',
        'playbackSpeed',
        'preferredQuality',
        'algorithm',
        'preferredTags',
        'blockedMakers',
      ];
    }

    final changed = <String>[];
    if (previous.autoPlay != current.autoPlay) changed.add('autoPlay');
    if (previous.showCaptions != current.showCaptions) {
      changed.add('showCaptions');
    }
    if (previous.playbackSpeed != current.playbackSpeed) {
      changed.add('playbackSpeed');
    }
    if (previous.preferredQuality != current.preferredQuality) {
      changed.add('preferredQuality');
    }
    if (previous.algorithm != current.algorithm) changed.add('algorithm');
    if (previous.preferredTags != current.preferredTags) {
      changed.add('preferredTags');
    }
    if (previous.blockedMakers != current.blockedMakers) {
      changed.add('blockedMakers');
    }
    return changed;
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
}
