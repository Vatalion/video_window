# Story 4-6: Feed Personalization & User Preferences

## Status
review

## Story
**As a** viewer,
**I want** to adjust my feed preferences (auto-play, tags, blocked makers, captions),
**so that** the feed aligns with my comfort and accessibility needs.

## Acceptance Criteria
1. Feed settings sheet allows toggling auto-play, captions, playback speed, preferred quality, and tag filters, persisting to Serverpod preferences. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
2. Preferences update endpoint recalculates personalization configuration and returns effective settings plus algorithm being used. [Source: docs/tech-spec-epic-4.md#implementation-guide]
3. **ACCESSIBILITY CRITICAL**: Reduced motion preference turns off auto-play and enables static preview thumbnails; captions toggle persists for future videos. [Source: docs/tech-spec-epic-4.md#technology-stack]
4. UI surfaces blocked maker list with ability to add/remove; backend ensures blocked IDs excluded from subsequent feed responses. [Source: docs/tech-spec-epic-4.md#data-models]
5. Analytics event `feed_preferences_updated` fires with diff metadata and experiment variants, ensuring traceability in Segment. [Source: docs/tech-spec-epic-4.md#analytics--observability]

## Prerequisites
1. Story 4.1 – Home Feed Implementation
2. Story 4.2 – Infinite Scroll & Pagination
3. Story 4.5 – Content Recommendation Engine Integration

## Tasks / Subtasks

### Flutter
- [x] Create `feed_settings_sheet.dart` with sections for playback, personalization, blocked makers, and accessibility options. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [x] Implement `update_feed_preferences_use_case.dart` to map form values to domain objects and call repository. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [x] Update `FeedBloc` to refresh feed state when preferences change and to adjust preload strategy accordingly. [Source: docs/tech-spec-epic-4.md#implementation-guide]

### Serverpod
- [x] Extend `feed_endpoint.dart` and `feed_service.dart` to persist `FeedConfiguration` entity, storing blocked makers and quality preferences. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [x] Update recommendation payloads to include user-configured tags and blocked makers. [Source: docs/tech-spec-epic-4.md#implementation-guide]

### Analytics & Compliance
- [x] Emit Segment + Datadog events for preference updates, capturing diff, algorithm, and session IDs. [Source: docs/tech-spec-epic-4.md#analytics--observability]
- [x] Ensure accessibility toggles recorded for WCAG reporting dashboard. [Source: docs/tech-spec-epic-4.md#success-criteria]

## Data Models
- `FeedConfiguration` entity persists user choices, including blocked makers and playback preferences. [Source: docs/tech-spec-epic-4.md#feed-configuration-entity]

## API Specifications
- `PUT /feed/preferences` accepts payload with playback + filtering settings and returns effective configuration. [Source: docs/tech-spec-epic-4.md#feed-endpoints]

## Component Specifications
- Preferences UI resides within `video_window_flutter/packages/features/timeline/lib/presentation/pages/feed_settings_sheet.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## File Locations
- Repository implementation in `video_window_flutter/packages/core/lib/data/repositories/feed/feed_repository.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## Testing Requirements
- Widget: `feed_settings_sheet_test.dart` verifying toggles, validation, and analytics triggers.
- Unit: `update_feed_preferences_use_case_test.dart` ensuring payload mapping and caching.
- Integration: `feed_preferences_integration_test.dart` verifying backend persistence and blocked maker filtering.

## Technical Constraints
- Preferences changes should reflect in feed within 2 swipes (<1 second) after update. [Source: docs/tech-spec-epic-4.md#implementation-guide]
- Blocked maker list limited to 200 entries to prevent payload bloat. [Source: docs/tech-spec-epic-4.md#data-models]

## Change Log
| Date       | Version | Description                               | Author            |
| ---------- | ------- | ----------------------------------------- | ----------------- |
| 2025-10-29 | v1.0    | Feed personalization story authored       | GitHub Copilot AI |
| 2025-11-10 | v1.1    | Story implementation complete - all tasks done, tests written, ready for review | BMAD Dev Agent |

## Dev Agent Record
### Agent Model Used
Composer (BMAD Dev Agent)

### Debug Log References
- Implementation completed: 2025-11-10
- All acceptance criteria implemented and tested
- Analytics events integrated for Segment/Datadog tracking

### Completion Notes List
- ✅ Created feed_settings_sheet.dart with all required sections (playback, personalization, blocked makers, accessibility)
- ✅ Implemented update_feed_preferences_use_case.dart with analytics integration
- ✅ Updated FeedBloc to handle FeedPreferencesUpdated event and refresh feed state
- ✅ Extended feed_endpoint.dart and feed_service.dart to persist FeedConfiguration
- ✅ Updated recommendation_bridge_service.dart to include blocked makers in payloads
- ✅ Added FeedPreferencesUpdatedEvent and FeedAccessibilityToggledEvent for analytics
- ✅ Implemented JSON serialization for FeedConfiguration entity
- ✅ Added comprehensive tests (widget, unit, integration)
- ✅ All acceptance criteria satisfied

### File List
**Flutter:**
- video_window_flutter/packages/features/timeline/lib/presentation/pages/feed_settings_sheet.dart
- video_window_flutter/packages/features/timeline/lib/use_cases/update_feed_preferences_use_case.dart
- video_window_flutter/packages/features/timeline/lib/presentation/bloc/feed_bloc.dart
- video_window_flutter/packages/features/timeline/lib/presentation/bloc/feed_event.dart
- video_window_flutter/packages/features/timeline/lib/domain/entities/feed_configuration.dart
- video_window_flutter/packages/features/timeline/lib/data/repositories/feed_repository.dart
- video_window_flutter/packages/features/timeline/lib/data/services/feed_analytics_events.dart

**Tests:**
- video_window_flutter/packages/features/timeline/test/presentation/pages/feed_settings_sheet_test.dart
- video_window_flutter/packages/features/timeline/test/use_cases/update_feed_preferences_use_case_test.dart
- video_window_flutter/packages/features/timeline/test/integration/feed_preferences_integration_test.dart

**Serverpod:**
- video_window_server/lib/src/endpoints/feed/feed_endpoint.dart
- video_window_server/lib/src/services/feed_service.dart
- video_window_server/lib/src/services/recommendation_bridge_service.dart

## QA Results
_(To be completed by QA Agent)_

## Dev Notes

### Implementation Guidance
- Follow architecture patterns defined in tech spec
- Reference epic context for integration points
- Ensure test coverage meets acceptance criteria requirements

### Key Considerations
- Review security requirements if authentication/authorization involved
- Check performance requirements and optimize accordingly
- Validate against Definition of Ready before starting implementation
