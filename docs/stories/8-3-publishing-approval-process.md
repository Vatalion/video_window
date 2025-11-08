# Story 8-3: Publishing Approval Process

## Status
Ready for Dev

## Story
**As a** maker,
**I want** to understand the approval process for my published content,
**so that** I can ensure compliance and track publication status

## Acceptance Criteria
1. Maker can see publication status (draft, pending_review, approved, published, rejected) with visual indicators and status definitions in maker dashboard.
2. **PERFORMANCE CRITICAL**: Maker receives real-time updates on approval progress via WebSocket connection with sub-second notification latency for status changes.
3. If rejected, maker can see specific feedback with violation categories, suggested corrections, and one-click resubmission workflow after addressing issues.
4. Maker can track average approval time and success rate in analytics dashboard with historical trends and comparative benchmarks.
5. Maker can withdraw story from review queue before admin decision with confirmation dialog and draft restoration.
6. Approved stories show publication timestamp, feed placement position, and initial engagement metrics (views, offers) in story detail view.

## Prerequisites
1. Story 8.1 – Publishing Workflow Implementation (publication status management)
2. Story 8.2 – Content Moderation Pipeline (moderation review and feedback system)
3. Story 11.1 – Notification System (real-time status notifications)
4. Story 3.1 – Viewer Profile Management (maker dashboard infrastructure)

## Tasks / Subtasks

### Phase 1 – Status Tracking UI & Real-Time Updates

- [ ] Build publication status indicators (AC: 1) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
  - [ ] Create `PublicationStatusBadge` widget with status-specific colors and icons
  - [ ] Display status in maker dashboard story list with tooltip definitions
  - [ ] Implement status filter/sort in story management view
  - [ ] Add status legend explaining each state (draft, pending_review, approved, published, rejected)
  - [ ] Show status transition history with timestamps in story detail drawer
- [ ] Implement progress timeline showing review stages (AC: 1, 2) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
  - [ ] Create `ReviewProgressTimeline` widget with stepper visualization
  - [ ] Display stages: Submitted → Under Review → Decision → Published/Rejected
  - [ ] Show estimated time remaining based on average review duration
  - [ ] Highlight current stage with pulsing animation for active reviews
  - [ ] Include timestamps for completed stages
- [ ] **PERFORMANCE CRITICAL**: Build real-time status notification system (AC: 2) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
  - [ ] Establish WebSocket connection for maker story status updates
  - [ ] Subscribe to story-specific channels on dashboard load
  - [ ] Handle status change events with optimistic UI updates
  - [ ] Display toast notifications for critical status changes (approved, rejected)
  - [ ] Update dashboard story list reactively without full refresh

### Phase 2 – Rejection Feedback & Resubmission

- [ ] Create detailed rejection feedback display (AC: 3) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
  - [ ] Build `RejectionFeedbackPanel` showing violation categories from moderation
  - [ ] Display specific sections requiring correction with highlighted issues
  - [ ] Show admin review notes with improvement suggestions
  - [ ] Provide links to content policy documentation and examples
  - [ ] Include appeal process information for disputed rejections
- [ ] Implement one-click resubmission workflow (AC: 3) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
  - [ ] Add "Edit & Resubmit" button on rejected story detail page
  - [ ] Navigate to story editor with rejection feedback sidebar overlay
  - [ ] Highlight sections requiring changes based on moderation feedback
  - [ ] Enable resubmission after maker confirms corrections made
  - [ ] Track resubmission attempts and display history (max 3 resubmissions)
- [ ] Build edit tracking for resubmitted content (AC: 3) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process & Story 8.4]
  - [ ] Create diff view showing changes between rejected and resubmitted versions
  - [ ] Log correction timestamps and sections modified
  - [ ] Display resubmission count and previous rejection reasons
  - [ ] Alert admin reviewers to resubmission context during review
  - [ ] Persist resubmission history for audit and learning purposes

### Phase 3 – Analytics Dashboard & Withdrawal

- [ ] Build maker publication analytics dashboard (AC: 4) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
  - [ ] Create `PublicationAnalyticsDashboard` page in maker profile section
  - [ ] Display approval rate metric: (approved / submitted) * 100
  - [ ] Show average review time with trend comparison (week/month/all-time)
  - [ ] Include historical submission chart with status breakdowns
  - [ ] Compare maker's metrics to platform averages (anonymized benchmarks)
- [ ] Implement story withdrawal workflow (AC: 5) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
  - [ ] Add "Withdraw from Review" action on pending_review stories
  - [ ] Show confirmation dialog explaining withdrawal consequences
  - [ ] Transition story status back to draft upon withdrawal
  - [ ] Notify admin of withdrawal to remove from moderation queue
  - [ ] Log withdrawal event for analytics and maker history
- [ ] Display publication success metrics (AC: 6) [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
  - [ ] Show publication timestamp and "time live" duration on story detail
  - [ ] Display feed placement ranking and visibility score
  - [ ] Include initial engagement metrics (views in first 24h, offers received)
  - [ ] Provide deep link to published story in feed from maker dashboard
  - [ ] Track publication performance over time with engagement graphs

## Dev Notes

### Previous Story Insights
- This is the third story in Epic 8, providing maker-facing visibility into the moderation process built in Story 8.2. It completes the feedback loop between moderation decisions and maker actions.

### Data Models
- `Story` entity includes `moderation_history` JSONB array tracking all status transitions with timestamps and reviewer notes. [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
- `ResubmissionAttempt` tracks correction cycles: story_id, attempt_number, submitted_at, changes_summary, previous_rejection_reason. [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
- Analytics aggregates: maker approval_rate, avg_review_duration_minutes, total_submissions, successful_publications. [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]

### API Specifications
- `GET /stories/{id}/status` returns current status, review progress, estimated completion time, and moderation feedback if rejected. [Source: docs/tech-spec-epic-8.md – Publishing Approval Process]
- `POST /stories/{id}/resubmit` transitions rejected story back to pending_review with resubmission metadata and incremented attempt counter.
- `POST /stories/{id}/withdraw` removes story from moderation queue and transitions to draft status with withdrawal timestamp.
- `GET /makers/{id}/publication-analytics` returns aggregated publication metrics with time-series data for dashboard visualizations.

### Component Specifications
- Publication status UI components in `video_window_flutter/packages/features/publishing/lib/presentation/widgets/`. [Source: docs/tech-spec-epic-8.md – Source Tree]
- Analytics dashboard in `video_window_flutter/packages/features/publishing/lib/presentation/pages/publication_analytics_dashboard.dart`.
- WebSocket integration leverages existing real-time infrastructure from notification system (Epic 11).
- Server endpoints in `video_window_server/lib/src/endpoints/story/` handle status queries, resubmission, and withdrawal workflows.
- Integration with analytics infrastructure from Epic 17 for historical metrics and trend analysis.

## Dev Agent Record

### Context Reference

- `docs/stories/8-3-publishing-approval-process.context.xml`

### Agent Model Used

<!-- Will be populated during dev-story execution -->

### Debug Log References

<!-- Will be populated during dev-story execution -->

### Completion Notes List

<!-- Will be populated during dev-story execution -->

### File List

<!-- Will be populated during dev-story execution -->

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-06 | v0.1 | Initial story creation | Bob (SM) |
