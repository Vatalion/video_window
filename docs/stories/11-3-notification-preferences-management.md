# Story 11-3: Notification Preferences & Channel Management

## Status
Ready for Dev

## Story
**As a** user (viewer or maker),
**I want** to control which notifications I receive and through which channels,
**so that** I only get alerts that matter to me without notification fatigue

## Acceptance Criteria
1. User can enable/disable notifications globally (push, email, in-app) with immediate effect across all notification types.
2. User can configure per-notification-type preferences for each channel (e.g., push for auction_won but email for shipping_reminder).
3. User can set quiet hours (start time, end time, days of week) to suppress non-critical notifications during specified periods.
4. **RELIABILITY CRITICAL**: Preference changes sync to server immediately with optimistic UI updates and rollback on failure.
5. Critical notifications (payment_received, auction_won) bypass quiet hours and cannot be disabled to protect business operations.
6. Notification preferences accessible from both Settings and Activity Feed with consistent UI and behavior.
7. User receives confirmation when preferences are saved successfully with clear indication of what changed.

## Prerequisites
1. Story 11.1 – Push Notification Infrastructure (notification delivery system)
2. Story 11.2 – In-App Activity Feed (notification center UI)
3. Story 3.5 – Account Settings Management (settings navigation structure)

## Tasks / Subtasks

### Phase 1 – Data Models & Repository

- [ ] Define notification preferences data models (AC: 1, 2, 3) [Source: docs/tech-spec-epic-11.md – Data Models]
  - [ ] Create `NotificationPreferences` entity with userId, pushEnabled, emailEnabled, inAppEnabled, typePreferences, quietHours, updatedAt
  - [ ] Create `ChannelPreference` model with push, email, inApp boolean flags
  - [ ] Create `QuietHoursConfig` model with startTime, endTime, daysOfWeek
  - [ ] Define default preferences for new users (all enabled except low priority)
- [ ] Implement preferences repository (AC: 1, 2, 3, 4) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Create `NotificationPreferencesRepository` in core package
  - [ ] Implement `getPreferences(userId)` method with caching
  - [ ] Implement `updatePreferences(userId, preferences)` method
  - [ ] Implement `updateChannelPreference(userId, type, channel, enabled)` method
  - [ ] Implement `updateQuietHours(userId, quietHoursConfig)` method
  - [ ] Add local storage for offline preference access
- [ ] Build Serverpod preferences endpoints (AC: 4) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Implement `GET /notifications/preferences` endpoint
  - [ ] Implement `PUT /notifications/preferences` endpoint
  - [ ] Implement `PATCH /notifications/preferences/channel` endpoint
  - [ ] Implement `PATCH /notifications/preferences/quiet-hours` endpoint
  - [ ] Create `notification_preferences` table with proper indexes
  - [ ] Validate quiet hours (start < end, valid days 1-7)

### Phase 2 – BLoC State Management

- [ ] Create NotificationPreferencesBloc (AC: 1, 2, 3, 4) [Source: docs/architecture/bloc-implementation-guide.md]
  - [ ] Create `NotificationPreferencesBloc` in features/notifications/presentation/bloc
  - [ ] Define events: LoadPreferences, UpdateGlobalChannel, UpdateTypePreference, UpdateQuietHours, SavePreferences
  - [ ] Define states: PreferencesInitial, PreferencesLoading, PreferencesLoaded, PreferencesSaving, PreferencesSaved, PreferencesError
  - [ ] Implement optimistic updates for all preference changes
  - [ ] Implement rollback on server update failure
  - [ ] Cache preferences locally for offline access
- [ ] Implement preference validation logic (AC: 5) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Define list of critical notification types that bypass quiet hours
  - [ ] Define list of critical notification types that cannot be fully disabled
  - [ ] Validate preference updates against business rules
  - [ ] Show warning messages when attempting to disable critical notifications
  - [ ] Allow disabling push/email but force in-app for critical types

### Phase 3 – Preferences UI

- [ ] Build Notification Preferences page (AC: 1, 2, 6) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Create `NotificationPreferencesPage` in features/notifications/presentation/pages
  - [ ] Add global toggle switches for Push, Email, In-App at top
  - [ ] Group notification types by category (Auctions, Orders, Content, System)
  - [ ] Display current preference state for each notification type
  - [ ] Show loading state while preferences load
  - [ ] Show error state with retry if preferences fail to load
- [ ] Create per-type preference controls (AC: 2, 5) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Create `NotificationTypePreferenceCard` widget
  - [ ] Display notification type name, description, and channel toggles
  - [ ] Show icon badge for critical notifications that bypass quiet hours
  - [ ] Disable toggle controls for mandatory critical notification channels
  - [ ] Show explanatory text for why critical notifications cannot be disabled
  - [ ] Apply immediate optimistic updates on toggle
- [ ] Implement quiet hours configuration (AC: 3) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Create `QuietHoursSection` widget with enable/disable toggle
  - [ ] Add time pickers for start and end times
  - [ ] Add day-of-week multi-select chips (Mon-Sun)
  - [ ] Validate start time < end time with error message
  - [ ] Show preview of when quiet hours will be active
  - [ ] Display note about critical notifications bypassing quiet hours
- [ ] Build save confirmation and error handling (AC: 4, 7) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Show snackbar confirmation when preferences saved successfully
  - [ ] List specific changes made in confirmation message
  - [ ] Show error snackbar with retry button on save failure
  - [ ] Revert optimistic updates on save failure
  - [ ] Add "Discard changes?" dialog if user navigates away with unsaved changes

### Phase 4 – Settings Integration

- [ ] Add notification preferences to Settings menu (AC: 6) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Add "Notifications" item to main settings menu
  - [ ] Navigate to NotificationPreferencesPage on tap
  - [ ] Show current global state (All enabled / Some disabled / All disabled)
  - [ ] Add notification badge if preferences need attention
- [ ] Add quick access from Activity Feed (AC: 6) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Add settings icon in Activity Feed AppBar
  - [ ] Navigate to NotificationPreferencesPage maintaining navigation context
  - [ ] Support deep link to specific notification type preferences
  - [ ] Preserve Activity Feed scroll position on return

### Phase 5 – Server-Side Preference Enforcement

- [ ] Implement preference checking in notification service (AC: 1, 2, 3, 5) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Load user preferences before sending notification
  - [ ] Check if notification type is enabled for requested channel
  - [ ] Skip notification if channel disabled for type
  - [ ] Check quiet hours and skip non-critical notifications
  - [ ] Always deliver critical notifications regardless of preferences
  - [ ] Log skipped notifications for analytics
- [ ] Build quiet hours evaluation logic (AC: 3, 5) [Source: docs/tech-spec-epic-11.md – Implementation Guide]
  - [ ] Calculate if current time falls within user's quiet hours
  - [ ] Account for timezone differences (use user's local timezone)
  - [ ] Check if current day of week is in quiet hours configuration
  - [ ] Queue non-critical notifications for delivery after quiet hours end
  - [ ] Implement batch delivery when quiet hours end

### Phase 6 – Testing

- [ ] Unit tests for preferences BLoC (AC: 1, 2, 3, 4) [Source: docs/testing/master-test-strategy.md]
  - [ ] Test LoadPreferences event and state transitions
  - [ ] Test UpdateGlobalChannel with optimistic updates
  - [ ] Test UpdateTypePreference for individual types
  - [ ] Test UpdateQuietHours validation
  - [ ] Test rollback on server update failure
  - [ ] Test critical notification validation rules
- [ ] Widget tests for preferences UI (AC: 1, 2, 3, 6, 7) [Source: docs/testing/master-test-strategy.md]
  - [ ] Test global toggle switches
  - [ ] Test per-type preference cards rendering
  - [ ] Test quiet hours time picker and day selection
  - [ ] Test validation error display
  - [ ] Test save confirmation snackbar
  - [ ] Test navigation from Settings and Activity Feed
- [ ] Integration tests for preference enforcement (AC: 5) [Source: docs/testing/master-test-strategy.md]
  - [ ] Test notification delivery respects channel preferences
  - [ ] Test quiet hours suppression of non-critical notifications
  - [ ] Test critical notifications bypass quiet hours
  - [ ] Test critical notifications cannot be fully disabled
  - [ ] Test preference sync across multiple devices
  - [ ] Test offline preference changes sync on reconnect

## Dev Notes
- Store quiet hours in UTC on server, convert to user local time in UI
- Consider adding "Notification Preview" to test current settings
- Implement preference migration strategy for schema changes
- Add analytics to track which preferences users change most
- Consider adding preset profiles (All, Essential Only, Off except critical)
- Test quiet hours edge cases (midnight crossover, DST changes)
- Implement preference export/import for user data portability
- Add warning before disabling all notifications

## Change Log
| Date | Author | Changes |
|------|--------|---------|
| 2025-10-30 | Mary (Analyst) | Initial story creation from tech spec |

## Dev Agent Record

### Context Reference

- `docs/stories/11-3-notification-preferences-management.context.xml`

### Agent Model Used

<!-- Will be populated during dev-story execution -->

### Debug Log References

<!-- Will be populated during dev-story execution -->

### Completion Notes List

<!-- Will be populated during dev-story execution -->

### File List

<!-- Will be populated during dev-story execution -->
