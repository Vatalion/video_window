# Story 14-1: Issue Reporting UI

## Status
ready-for-dev

**Epic:** 14 - Issue Resolution & Refund Handling  
**Story Points:** 5  
**Priority:** HIGH  
**Status:** Ready  
**Sprint:** 9

---

## User Story

**As a** buyer who received an item with issues  
**I want to** report problems within 48 hours of delivery  
**So that** I can request a resolution or refund

---

## Acceptance Criteria

## Tasks / Subtasks

<!-- Tasks will be defined based on acceptance criteria -->
- [ ] Task 1: Define implementation tasks
  - [ ] Subtask 1.1: Break down acceptance criteria into actionable items

### Functional Requirements
1. **Issue Reporting Form**
   - Available 48 hours after delivery confirmation
   - Required fields: issue type (damaged/not-as-described/missing), description, photos (min 2, max 6)
   - Photo upload with compression (max 5MB per image)
   - Preview before submission
   
2. **Issue Type Selection**
   - "Item Damaged in Shipping" → Auto-suggest filing with carrier
   - "Not as Described" → Requires description comparison
   - "Item Never Arrived" → Check tracking status first
   
3. **Automatic Validation**
   - Must be within 48-hour window
   - Order must be in "delivered" status
   - Cannot file duplicate issues for same order
   
4. **Submission Confirmation**
   - Display issue ID
   - Estimated response time (24 hours)
   - Next steps explanation
   - Email confirmation sent

### Technical Requirements
1. Database: Insert into `disputes` table with status "pending"
2. S3 upload for evidence photos with signed URLs
3. Push notification to seller
4. Audit log entry created

### UI/UX Requirements
1. Mobile-first form design
2. Image upload with drag-drop (web) and gallery picker (mobile)
3. Character count for description (min 50, max 1000)
4. Accessibility: WCAG 2.1 AA compliant

---

## Tasks

- Implement the Flutter issue reporting form with validations, photo capture/upload, and eligibility gating based on delivery timestamp.
- Create Serverpod endpoint logic that writes disputes, evidence records, and audit entries while preventing duplicates per order.
- Wire notifications and email/SMS templates that alert sellers and support staff when a new dispute is filed.
- Document the workflow and update support runbooks with screenshots and user guidance.

---

## Technical Notes

### Database Schema
```sql
disputes(
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  buyer_id UUID REFERENCES users(id),
  issue_type VARCHAR(50),
  description TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  filed_at TIMESTAMP DEFAULT NOW()
)

dispute_evidence(
  id UUID PRIMARY KEY,
  dispute_id UUID REFERENCES disputes(id),
  file_url TEXT,
  uploaded_at TIMESTAMP DEFAULT NOW()
)
```

### API Endpoints
- `POST /api/disputes` - Create new dispute
- `POST /api/disputes/{id}/evidence` - Upload evidence photos
- `GET /api/orders/{id}/dispute-eligibility` - Check if order can file dispute

---

## Dependencies
- Epic 13 (Shipping & Tracking) - Need delivery confirmation
- Epic 11 (Notifications) - Push notifications to seller
- Epic 3 (Content Management) - S3 upload infrastructure

---

## Definition of Done
- [ ] Issue reporting form implemented in Flutter
- [ ] 48-hour eligibility check enforced
- [ ] Photo upload to S3 functional
- [ ] Dispute record created in database
- [ ] Seller notification triggered
- [ ] Unit tests: 80%+ coverage
- [ ] Widget tests for form validation
- [ ] Integration test: End-to-end dispute filing
- [ ] Accessibility audit passed
- [ ] Code review approved
- [ ] Documentation updated

---

**Created:** 2025-11-01  
**Last Updated:** 2025-11-01

## Dev Agent Record

### Context Reference

- `docs/stories/14-1-issue-reporting-ui.context.xml`

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
