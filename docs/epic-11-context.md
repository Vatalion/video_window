# Epic 11 Context: Notifications & Alerts

**Generated:** 2025-11-04  
**Epic ID:** 11  
**Epic Title:** Notifications & Alerts  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Push Notifications:** Firebase Cloud Messaging (FCM) for Android + iOS
- **In-App Feed:** Activity center with real-time updates via WebSocket
- **Multi-Channel:** Push, in-app, email (SendGrid fallback)
- **Preferences:** Per-channel controls with quiet hours (timezone-aware)
- **Maker SLA Alerts:** Critical notifications for shipping deadlines (72h tracking SLA)

### Technology Stack
- Flutter: firebase_messaging 14.7.9, flutter_local_notifications 16.3.0
- Serverpod: Notification service, event processors, delivery tracking
- FCM: Multi-platform push delivery
- Redis 7.2.4: Real-time event queue, deduplication cache
- PostgreSQL 15: notifications, user_preferences, delivery_receipts tables
- SendGrid API v3: Email fallback notifications

### Key Integration Points
- `packages/features/notifications/` - Notification UI and preferences
- `video_window_server/lib/src/endpoints/notifications/` - Notification endpoints
- Firebase Cloud Messaging: Push token management and delivery
- Redis: Real-time notification queue with priority

### Implementation Patterns
- **Device Registration:** FCM token refresh on app launch, token rotation handling
- **Multi-Channel Delivery:** Push (immediate) → In-app (fallback) → Email (final fallback)
- **Quiet Hours:** Time-based delivery suppression with timezone support
- **Priority Handling:** Critical (immediate delivery) vs Normal (batched/scheduled)

### Story Dependencies
1. **11.1:** Push notification infrastructure & device registration (foundation)
2. **11.2:** In-app activity feed & notification center (parallel with 11.1)
3. **11.3:** Notification preferences & channel management (depends on 11.1, 11.2)
4. **11.4:** Maker-specific alerts & SLA notifications (depends on all above)

### Success Criteria
- Push notifications deliver in <10 seconds (P95)
- Activity feed updates in real-time (<2s latency)
- User preferences honored 100% of the time
- SLA alerts never missed (72h tracking deadline warnings)
- Quiet hours respected across all channels

**Reference:** See `docs/tech-spec-epic-11.md` for full specification
