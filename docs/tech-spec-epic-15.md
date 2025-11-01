# Tech Spec: Epic 15 - Admin Moderation Toolkit

**Epic ID:** 15 | **Created:** 2025-10-31 | **Priority:** Operations

## Overview
Equip internal teams with admin dashboard for user/listing moderation, policy enforcement, and audit trails.

## Architecture
- **Admin Portal:** Flutter Web with SSO/MFA
- **User Search:** Elasticsearch index for fast lookup
- **Policy Engine:** Configurable rules (strikes, cooldowns, suspensions)
- **Audit Log:** All admin actions tracked with reason codes

## Database Schema
```sql
CREATE TABLE admin_actions (
  id UUID PRIMARY KEY,
  admin_id UUID NOT NULL,
  action_type VARCHAR(50), -- takedown, suspension, warning
  target_type VARCHAR(20), -- user, listing
  target_id UUID NOT NULL,
  reason_code VARCHAR(50),
  evidence_s3_key VARCHAR(512),
  appeal_deadline TIMESTAMPTZ,
  created_at TIMESTAMPTZ
);
```

## Implementation
1. **Story 15.1:** Admin portal with user/listing search (Elasticsearch)
2. **Story 15.2:** Takedown flow with notifications and appeal option
3. **Story 15.3:** Policy config UI for thresholds and templates

## Success Metrics
- Takedown execution time: <5 minutes
- Policy update deployment: <1 hour (no code deploy)
- Audit compliance: 100% actions logged

**Status:** Draft | **Owner:** Winston + BMad Master
