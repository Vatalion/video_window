import '../config/app_config.dart';

/// Abstract base class for all analytics events
///
/// Events represent user actions, screen views, or system events
/// that should be tracked for product analytics.
abstract class AnalyticsEvent {
  /// Unique name identifying the event type
  String get name;

  /// Key-value properties providing event context
  Map<String, dynamic> get properties;

  /// When the event occurred
  DateTime get timestamp;
}

/// Core analytics service for event tracking
///
/// Features:
/// - Privacy-aware tracking (respects user opt-out)
/// - Event batching for efficiency
/// - Graceful error handling
/// - Planned BigQuery integration
///
/// Usage:
/// ```dart
/// final analytics = AnalyticsService(config);
/// await analytics.trackEvent(ScreenViewEvent('home'));
/// await analytics.dispose(); // Flush on app close
/// ```
class AnalyticsService {
  final AppConfig _config;
  final List<AnalyticsEvent> _eventQueue = [];
  bool _disposed = false;

  AnalyticsService(this._config);

  /// Track an analytics event
  ///
  /// If analytics is disabled via config, the event is silently dropped.
  /// Events are batched and flushed when the queue reaches 10 events.
  Future<void> trackEvent(AnalyticsEvent event) async {
    if (_disposed) {
      throw StateError('Cannot track events after dispose');
    }

    if (!_config.enableAnalytics) {
      return; // Respect privacy - no tracking
    }

    _eventQueue.add(event);

    // Batch events for efficiency
    if (_eventQueue.length >= 10) {
      await _flushEvents();
    }
  }

  /// Flush all pending events to the backend
  ///
  /// This is called automatically when the batch threshold is reached,
  /// or manually via dispose() when the app is closing.
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty) return;

    try {
      // Serialize events for backend
      final events = _eventQueue
          .map((e) => {
                'name': e.name,
                'properties': e.properties,
                'timestamp': e.timestamp.toIso8601String(),
              })
          .toList();

      // TODO(epic-02): Implement actual BigQuery integration
      // For now, just log to console for development
      // ignore: avoid_print
      print('Analytics: Flushing ${events.length} events');

      _eventQueue.clear();
    } catch (e) {
      // Gracefully handle errors - don't crash the app
      // ignore: avoid_print
      print('Analytics error: $e');
      // Keep events in queue for retry on next flush
    }
  }

  /// Get the current queue size (for testing)
  int get queueSize => _eventQueue.length;

  /// Flush remaining events and clean up resources
  ///
  /// Should be called when the app is closing or the service is no longer needed.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _flushEvents();
  }
}

// ============================================================================
// Common Event Types
// ============================================================================

/// Event fired when a user navigates to a new screen
///
/// Example:
/// ```dart
/// analytics.trackEvent(ScreenViewEvent('home'));
/// analytics.trackEvent(ScreenViewEvent('story_detail'));
/// ```
class ScreenViewEvent extends AnalyticsEvent {
  final String screenName;
  final DateTime _timestamp;

  ScreenViewEvent(this.screenName) : _timestamp = DateTime.now();

  @override
  String get name => 'screen_view';

  @override
  Map<String, dynamic> get properties => {'screen_name': screenName};

  @override
  DateTime get timestamp => _timestamp;
}

/// Event fired when a user performs an action
///
/// Example:
/// ```dart
/// analytics.trackEvent(UserActionEvent('button_tap', context: {
///   'button_id': 'make_offer',
///   'story_id': '123',
/// }));
/// ```
class UserActionEvent extends AnalyticsEvent {
  final String action;
  final Map<String, dynamic> context;
  final DateTime _timestamp;

  UserActionEvent(this.action, {this.context = const {}})
      : _timestamp = DateTime.now();

  @override
  String get name => 'user_action';

  @override
  Map<String, dynamic> get properties => {
        'action': action,
        ...context,
      };

  @override
  DateTime get timestamp => _timestamp;
}
