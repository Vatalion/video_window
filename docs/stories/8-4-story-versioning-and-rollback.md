# Story 8-4: Story Versioning and Rollback

## Status
Ready for Dev

## Story
**As a** maker,
**I want** to make updates to published stories and rollback changes if needed,
**so that** I can improve content while maintaining publication history

## Acceptance Criteria
1. Maker can edit published story content (text, images, process timeline, materials) without unpublishing, with edit mode clearly distinguished from view mode.
2. **BUSINESS CRITICAL**: Each edit creates a new version with timestamp, changes log, and full content snapshot, ensuring complete version history for audit and rollback.
3. Maker can preview changes before publishing updates with side-by-side comparison of current and modified versions.
4. Maker can rollback to any previous version with one-click restoration and automatic version increment upon rollback.
5. Version history is visible with change summaries, timestamps, edit reasons, and visual diff highlighting of modifications between versions.
6. **BUSINESS CRITICAL**: Active offers and auctions are preserved during content updates with offer references locked to original version to prevent bait-and-switch.

## Prerequisites
1. Story 8.1 – Publishing Workflow Implementation (published story status management)
2. Story 8.3 – Publishing Approval Process (resubmission workflow foundation)
3. Story 9.1 – Offer Submission Flow (offer entity and linking to stories)
4. Story 10.1 – Auction Timer State Management (auction entity and state)

## Tasks / Subtasks

### Phase 1 – Version Control System

- [ ] **BUSINESS CRITICAL**: Design story version database schema (AC: 2) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Create `story_versions` table with version_number, created_at, content_snapshot JSONB
  - [ ] Store complete story content (overview, timeline, materials, notes) as immutable snapshot
  - [ ] Add `change_summary` text field describing modifications made
  - [ ] Include `edit_reason` field for maker to document why changes were made
  - [ ] Link versions to parent story_id with cascade deletion protection
- [ ] Implement change detection and diff generation (AC: 2, 5) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Create `StoryDiffService` to compute JSON diffs between versions
  - [ ] Detect changes in text fields (overview, timeline, materials, notes)
  - [ ] Track image/media changes (added, removed, replaced)
  - [ ] Generate human-readable change summaries from diffs
  - [ ] Store diff metadata for efficient version comparison
- [ ] Build version storage and retrieval APIs (AC: 2, 5) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Implement `POST /stories/{id}/versions` to create new version snapshot
  - [ ] Create `GET /stories/{id}/versions` to retrieve version history list
  - [ ] Add `GET /stories/{id}/versions/{version}` to fetch specific version content
  - [ ] Implement `GET /stories/{id}/versions/{v1}/diff/{v2}` for version comparison
  - [ ] Enforce version immutability after creation (no updates allowed)

### Phase 2 – Edit and Update Workflow

- [ ] Create edit mode for published stories (AC: 1) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Add "Edit Published Story" action in maker dashboard story detail
  - [ ] Load story editor with current published content pre-filled
  - [ ] Display "Editing Published Story" banner with version context
  - [ ] Enable editing of text fields, images, and timeline without unpublishing
  - [ ] Require edit reason before saving changes
- [ ] Implement change preview with comparison (AC: 3) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Create `VersionComparisonView` showing side-by-side current vs. modified
  - [ ] Highlight changed sections with diff visualization (additions, deletions)
  - [ ] Show image changes with before/after thumbnail comparisons
  - [ ] Display text diffs with inline highlighting of modifications
  - [ ] Provide "Publish Update" or "Continue Editing" options after preview
- [ ] Update publication with version increment (AC: 2) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Create new version snapshot when maker publishes update
  - [ ] Increment version_number automatically (v1, v2, v3...)
  - [ ] Update story content with new version while preserving old versions
  - [ ] Trigger moderation review if changes are substantial (configurable threshold)
  - [ ] Notify viewers who saved/favorited story about update

### Phase 3 – Rollback Functionality & Offer Preservation

- [ ] Build version history browser interface (AC: 5) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Create `VersionHistoryPage` displaying timeline of all versions
  - [ ] Show version number, timestamp, edit reason, and change summary for each
  - [ ] Provide "View Version" action to see full content of any version
  - [ ] Highlight currently published version with distinct styling
  - [ ] Display diff links between consecutive versions
- [ ] Implement one-click rollback to previous version (AC: 4) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Add "Rollback to This Version" action on version history entries
  - [ ] Show confirmation dialog with rollback impact summary
  - [ ] Create new version snapshot upon rollback (preserves full history)
  - [ ] Update story content with selected historical version
  - [ ] Log rollback event with reason and target version reference
- [ ] **BUSINESS CRITICAL**: Preserve active offers/auctions during updates (AC: 6) [Source: docs/tech-spec-epic-8.md – Content Versioning]
  - [ ] Lock offer references to story version at time of offer creation
  - [ ] Store `story_version_id` in Offer entity for immutable reference
  - [ ] Prevent content changes that would materially affect active auctions
  - [ ] Display warning when editing story with active offers/auctions
  - [ ] Show buyers which version they made offer on if content has changed
  - [ ] Implement offer invalidation if rollback materially alters item

## Dev Notes

### Previous Story Insights
- This is the final story in Epic 8, completing the content lifecycle management system. It builds on versioning concepts from Story 8.3 (resubmission tracking) and must preserve commerce integrity from Epics 9-10.

### Data Models
- `StoryVersion` entity: id, story_id, version_number, created_at, content_snapshot JSONB, change_summary, edit_reason, created_by_maker_id. [Source: docs/tech-spec-epic-8.md – Content Versioning]
- `Offer` entity adds `story_version_id` foreign key linking offer to specific content version at time of submission. [Source: docs/tech-spec-epic-8.md – Content Versioning]
- Content snapshot structure: `{ "overview": {}, "timeline": [], "materials": [], "notes": {}, "media": [] }` - complete story state. [Source: docs/tech-spec-epic-8.md – Content Versioning]

### API Specifications
- `POST /stories/{id}/versions` accepts edit_reason and creates immutable version snapshot before applying updates. [Source: docs/tech-spec-epic-8.md – Content Versioning]
- `POST /stories/{id}/rollback/{version}` validates no active auctions would be invalidated, then creates new version with historical content.
- `GET /stories/{id}/versions/{v1}/diff/{v2}` returns structured diff with field-level changes and human-readable summaries.
- Version snapshots compressed using gzip before storage to optimize database size (typically 70-80% reduction).

### Component Specifications
- Version management UI in `video_window_flutter/packages/features/publishing/lib/presentation/pages/version_history_page.dart`. [Source: docs/tech-spec-epic-8.md – Source Tree]
- Version diff service in `video_window_flutter/packages/core/lib/services/versioning/story_diff_service.dart` using JSON diff algorithms.
- Server versioning endpoints in `video_window_server/lib/src/endpoints/story/versions.dart` manage immutable version storage.
- PostgreSQL JSONB indexing on content_snapshot for efficient version queries and diff operations.
- Integration with offer/auction systems (Epics 9-10) to enforce version locking and prevent bait-and-switch scenarios.

## Dev Agent Record

### Context Reference

- `docs/stories/8-4-story-versioning-and-rollback.context.xml`

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
