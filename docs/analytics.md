# Analytics Service Foundation

## Overview

The Analytics Service provides event tracking infrastructure for understanding user behavior in the Video Window marketplace. It follows a privacy-first approach with user opt-out controls and efficient event batching.

## Architecture

### Core Components

**AnalyticsEvent** (abstract base class)
- Defines the contract for all analytics events
- Properties: `name` (string), `properties` (map), `timestamp` (DateTime)

**AnalyticsService** (main service class)
- Manages event tracking, batching, and flushing
- Respects privacy controls via `AppConfig.enableAnalytics`
- Automatically batches 10 events before flushing
- Gracefully handles errors without crashing the app

### Event Types

**ScreenViewEvent**
- Tracks screen/page navigation
- Properties: `screen_name`

**UserActionEvent**
- Tracks user interactions
- Properties: `action`, plus any additional context

## Usage

### Basic Tracking

```dart
// Initialize service
final config = await AppConfig.load();
final analytics = AnalyticsService(config);

// Track screen views
await analytics.trackEvent(ScreenViewEvent('home'));
await analytics.trackEvent(ScreenViewEvent('story_detail'));

// Track user actions
await analytics.trackEvent(UserActionEvent('button_tap', context: {
  'button_id': 'make_offer',
  'story_id': '123',
  'amount': 50.0,
}));

// Clean up on app close
await analytics.dispose();
```

### Creating Custom Events

```dart
class VideoPlaybackEvent extends AnalyticsEvent {
  final String videoId;
  final int durationSeconds;
  final DateTime _timestamp;

  VideoPlaybackEvent(this.videoId, this.durationSeconds)
      : _timestamp = DateTime.now();

  @override
  String get name => 'video_playback';

  @override
  Map<String, dynamic> get properties => {
    'video_id': videoId,
    'duration_seconds': durationSeconds,
  };

  @override
  DateTime get timestamp => _timestamp;
}

// Use it
await analytics.trackEvent(VideoPlaybackEvent('vid_123', 45));
```

### Integration with BLoC

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  final AnalyticsService _analytics;

  MyBloc(this._analytics) {
    on<ButtonPressed>((event, emit) async {
      await _analytics.trackEvent(UserActionEvent('button_pressed', context: {
        'button_id': event.buttonId,
      }));
      
      // ... rest of business logic
    });
  }
}
```

## Event Batching

Events are queued locally and flushed to the backend when:
- Queue reaches 10 events (automatic threshold)
- `dispose()` is called (app closing)

This reduces network calls while ensuring events aren't lost.

## Privacy Controls

Analytics respects the `enableAnalytics` flag from AppConfig:
- When `true`: Events are tracked normally
- When `false`: Events are silently dropped (no tracking)

The flag is controlled via environment configuration:

```json
// assets/config/dev.json
{
  "enableAnalytics": true
}
```

Users can opt-out via privacy settings (future enhancement).

## BigQuery Integration (Planned)

The service includes a TODO for BigQuery integration:

```dart
// TODO(epic-02): Implement actual BigQuery integration
// Current: Console logging for development
// Future: POST events to BigQuery streaming API
```

### Planned Implementation

1. **Endpoint**: Serverpod endpoint to receive batched events
2. **Backend**: Server streams events to BigQuery via REST API
3. **Schema**: BigQuery table with columns:
   - `event_name` (STRING)
   - `properties` (JSON)
   - `timestamp` (TIMESTAMP)
   - `user_id` (STRING, nullable)
   - `session_id` (STRING)

## Event Schema

All events follow a consistent structure when serialized:

```json
{
  "name": "screen_view",
  "properties": {
    "screen_name": "home"
  },
  "timestamp": "2025-11-06T14:30:00.000Z"
}
```

### Naming Conventions

- **Event names**: `snake_case` (e.g., `screen_view`, `user_action`)
- **Property keys**: `snake_case` (e.g., `screen_name`, `button_id`)
- **Screen names**: `snake_case` (e.g., `home`, `story_detail`, `make_offer`)
- **Action names**: `snake_case` (e.g., `button_tap`, `make_offer`, `video_play`)

## Testing

### Unit Tests

The service includes comprehensive tests covering:
- Event tracking when enabled/disabled
- Batch threshold behavior
- Dispose cleanup
- Event structure validation
- Timestamp capture

Run tests:
```bash
cd video_window_flutter/packages/core
flutter test test/services/analytics_service_test.dart
```

### Manual Testing

Use debug mode to see console output:

```dart
final config = AppConfig(
  environment: Environment.dev,
  enableAnalytics: true,
  debugMode: true,
  // ... other config
);
```

Watch for console logs:
```
Analytics: Flushing 10 events
```

## Future Enhancements

1. **User Identification**: Attach user_id to events after authentication
2. **Session Tracking**: Generate and persist session IDs
3. **Offline Persistence**: Store events locally if network unavailable
4. **Event Filtering**: Block sensitive events from tracking
5. **Real-time Flushing**: Time-based flush in addition to count-based
6. **A/B Testing Integration**: Tie events to experiment variants

## Error Handling

The service handles errors gracefully:
- Backend failures don't crash the app
- Failed flushes leave events in queue for retry
- Logs errors to console in debug mode

## Performance Considerations

- **Batching**: Reduces network overhead
- **Async**: All operations are non-blocking
- **Memory**: Queue is capped at 10 events before flush
- **CPU**: Minimal overhead per event

## Related Documentation

- [Configuration Management](./configuration-management.md)
- [Tech Spec Epic 02](./tech-spec-epic-02.md)
- [Story 02-4](./stories/02-4-analytics-service-foundation.md)

---

**Last Updated**: 2025-11-06  
**Status**: Foundation complete, BigQuery integration pending
