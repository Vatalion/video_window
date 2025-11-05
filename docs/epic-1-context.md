# Epic 1 Context: Authentication & Identity

**Generated:** 2025-11-04  
**Epic ID:** 1  
**Epic Title:** Authentication & Identity  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Auth Methods:** Email OTP + Social (Google, Apple)
- **Sessions:** JWT with RS256 signing, refresh token rotation
- **Storage:** flutter_secure_storage for tokens
- **Backend:** Serverpod Identity Service endpoints

### Technology Stack
- Flutter: flutter_secure_storage 9.2.2, google_sign_in 6.2.1, sign_in_with_apple 6.1.1
- Serverpod 2.9.2: Identity and session endpoints
- Email: SendGrid API v3 via sendgrid-dart 7.12.0
- Crypto: bcrypt 4.0.1 (OTP), package:jwt 3.0.1 (RS256)
- Data: PostgreSQL 15, Redis 7.2.4 (rate limiting)
- Secrets: 1Password Connect 1.7.3

### Key Integration Points
- `packages/features/auth/` - Authentication feature package
- `video_window_server/lib/src/endpoints/identity/` - Auth endpoints
- PostgreSQL: users, sessions, verification_tokens tables
- Redis: Rate limiting and token blacklist

### Implementation Patterns
- **OTP Flow:** Generate → Email → Verify → Create session
- **Social OAuth:** Platform SDK → Backend verify → Create session
- **Session Management:** Access token (15min) + Refresh token (30 days)
- **Security:** Rate limiting, token rotation, secure storage

### Story Dependencies
1. **1.1:** Email OTP (foundation)
2. **1.2:** Social login (parallel with 1.1)
3. **1.3:** Session management (depends on 1.1, 1.2)
4. **1.4:** Account recovery (depends on all)

### Success Criteria
- Users can authenticate via email OTP or social login
- Sessions persist across app restarts
- Account recovery functional within 5 minutes
- Security: Rate limiting blocks brute force attempts

**Reference:** See `docs/tech-spec-epic-1.md` for full specification
