# Epic 15 Context: Moderation & Compliance

**Generated:** 2025-11-04  
**Epic ID:** 15  
**Epic Title:** Moderation & Compliance  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Admin Portal:** Flutter Web application with SSO/MFA authentication
- **Search Infrastructure:** Elasticsearch for fast user/listing fuzzy search
- **Policy Engine:** Configurable rules (strikes, cooldowns, suspensions) without code deployment
- **Audit Trail:** Immutable log of all admin actions with reason codes
- **Appeal Process:** Optional appeal mechanism with deadline tracking

### Technology Stack
- Flutter Web: Admin dashboard and moderation tools
- Elasticsearch: User/listing search index with fuzzy matching
- PostgreSQL: admin_actions, policy_config, appeal_requests tables
- SSO/MFA: Auth0 or similar for admin access control
- Audit: Complete immutable action history with cryptographic signatures

### Key Integration Points
- Admin portal (Flutter Web with role-based access)
- `video_window_server/lib/src/endpoints/admin/` - Admin and moderation endpoints
- Elasticsearch: Fast search for users/listings with filters
- Notification service: Takedown/suspension/warning notifications

### Implementation Patterns
- **Admin Search:** Elasticsearch with fuzzy matching, filters (status, flags, date ranges)
- **Takedown Flow:** Reason code selection → Evidence attachment → Automated notification → Appeal window
- **Policy Configuration:** No-code policy rule editor (JSON-based rules engine)
- **Audit Trail:** Immutable append-only log with cryptographic chain verification

### Story Dependencies
1. **15.1:** Admin portal with user/listing search (foundation)
2. **15.2:** Takedown flow with notifications & appeals (depends on 15.1)
3. **15.3:** Policy config UI for rules & templates (depends on 15.1)

### Success Criteria
- Takedown execution completes in <5 minutes
- Policy updates deploy in <1 hour (no code changes required)
- 100% of admin actions logged in audit trail
- Appeal process operational with SLA tracking
- Search responds in <500ms for user/listing queries

**Reference:** See `docs/tech-spec-epic-15.md` for full specification
