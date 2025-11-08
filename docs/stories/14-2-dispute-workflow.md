# Story 14-2: Dispute Workflow Management

**Epic:** 14 - Issue Resolution & Refund Handling  
**Story Points:** 8  
**Priority:** HIGH  
**Status:** Ready  
**Sprint:** 9

---

## User Story

**As a** platform administrator  
**I want to** manage dispute resolution workflows  
**So that** buyers and sellers can reach fair resolutions

---

## Acceptance Criteria

## Tasks / Subtasks

<!-- Tasks will be defined based on acceptance criteria -->
- [ ] Task 1: Define implementation tasks
  - [ ] Subtask 1.1: Break down acceptance criteria into actionable items

### Functional Requirements
1. **Dispute State Machine**
   - States: pending → investigating → resolved/escalated/rejected
   - SLA tracking: 24h for initial response, 5 days for resolution
   - Auto-escalate if SLA breached
   
2. **Admin Investigation Tools**
   - View all evidence (photos, tracking, messages)
   - Request additional information from buyer/seller
   - Add internal notes (not visible to users)
   - Timeline view of all dispute actions
   
3. **Resolution Options**
   - Full refund (with/without return)
   - Partial refund
   - No refund (reject dispute)
   - Seller replacement offer
   
4. **Communication**
   - In-app messaging between buyer/seller/admin
   - Email notifications for status changes
   - 48-hour response window for each party

### Technical Requirements
1. Database: `dispute_timeline` table for audit trail
2. State machine implementation with validation rules
3. SLA monitoring with background jobs
4. Admin portal integration (Flutter Web)

### UI/UX Requirements
1. Admin dashboard: List view with filters (status, SLA breach)
2. Dispute detail page with evidence gallery
3. Action buttons based on current state
4. Timeline visualization

---

## Tasks

- Implement the dispute state machine service with SLA timers, auto-escalation, and validation of allowable transitions.
- Build the Flutter admin portal experiences for dispute list, detail view, and action controls with realtime updates.
- Create Serverpod endpoints and repositories to persist timeline events, internal notes, and messaging threads.
- Configure background jobs and notifications that monitor SLA breaches and alert assigned reviewers.

---

## Technical Notes

### State Machine
```dart
enum DisputeStatus {
  pending,       // Initial state
  investigating, // Admin reviewing
  resolved,      // Resolution accepted
  escalated,     // Needs higher-level review
  rejected       // Dispute denied
}

Map<DisputeStatus, List<DisputeStatus>> allowedTransitions = {
  DisputeStatus.pending: [DisputeStatus.investigating, DisputeStatus.rejected],
  DisputeStatus.investigating: [DisputeStatus.resolved, DisputeStatus.escalated],
  DisputeStatus.escalated: [DisputeStatus.resolved, DisputeStatus.rejected],
};
```

### Database Schema
```sql
dispute_timeline(
  id UUID PRIMARY KEY,
  dispute_id UUID REFERENCES disputes(id),
  actor_id UUID REFERENCES users(id),
  action VARCHAR(50),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
)
```

---

## Dependencies
- Epic 14.1 (Issue Reporting) - Need disputes to exist
- Epic 15 (Admin Moderation) - Admin portal infrastructure
- Epic 11 (Notifications) - Status change notifications

---

## Definition of Done
- [ ] State machine implemented with validation
- [ ] Admin investigation UI complete
- [ ] SLA tracking with auto-escalation
- [ ] Dispute timeline audit trail
- [ ] Communication system functional
- [ ] Unit tests: 85%+ coverage
- [ ] Integration tests: State transitions
- [ ] Load test: 100 concurrent disputes
- [ ] Admin training documentation
- [ ] Code review approved

---

**Created:** 2025-11-01  
**Last Updated:** 2025-11-01

## Dev Agent Record

### Context Reference

- `docs/stories/14-2-dispute-workflow.context.xml`

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
