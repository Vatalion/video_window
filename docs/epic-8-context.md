# Epic 8 Context: Publishing & Moderation

**Generated:** 2025-11-04  
**Epic ID:** 8  
**Epic Title:** Publishing & Moderation  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Publishing Lifecycle:** Draft → Pending Review → Approved → Published state machine
- **Moderation Queue:** Priority-based queue (flagged content first, then FIFO)
- **Scheduling:** Publish immediately or schedule for future timestamp
- **Versioning:** Content snapshots with immutable version history and rollback
- **Admin Tools:** Moderation dashboard with action audit trail

### Technology Stack
- Flutter 3.19.6: Maker publishing UI, admin moderation dashboard
- Serverpod 2.9.2: Publishing workflows, moderation service, version control
- PostgreSQL 15: content_versions table with JSONB snapshots
- Redis 7.2.4: Moderation queue with priority scoring
- AWS S3: Version snapshot storage for media assets

### Key Integration Points
- `packages/features/timeline/` - Publishing UI and draft review
- `video_window_server/lib/src/endpoints/publishing/` - Publishing lifecycle endpoints
- `video_window_server/lib/src/services/moderation/` - Moderation queue and admin service
- PostgreSQL: content_versions table with full snapshot history

### Implementation Patterns
- **Status State Machine:** Draft → Pending Review → Approved/Rejected → Published/Archived
- **Moderation Priority:** Flagged content (priority 1) → Age-based FIFO (normal queue)
- **Content Versioning:** Snapshot on every state transition with immutable history
- **Rollback Capability:** Restore any previous version with audit trail

### Story Dependencies
1. **8.1:** Draft review & publishing UI (foundation)
2. **8.2:** Moderation queue & admin tools (parallel with 8.1)
3. **8.3:** Publishing workflow & scheduling (depends on 8.1, 8.2)
4. **8.4:** Content versioning & rollback (depends on all above)

### Success Criteria
- Moderation queue prioritizes flagged content correctly
- Publishing completes in <5 seconds
- Versioning enables 1-click rollback to any previous state
- Admin dashboard tracks 100% of moderation actions
- Scheduled publishing executes within 60s of target time

**Reference:** See `docs/tech-spec-epic-8.md` for full specification
