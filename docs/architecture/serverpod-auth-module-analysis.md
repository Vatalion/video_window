# Serverpod Auth Module Analysis

**Date:** 2025-11-10
**Decision Status:** EVALUATED - Custom Implementation Required
**Reviewed By:** Dev Team

## Overview

Serverpod provides a built-in authentication module (`serverpod_auth`) that offers baseline authentication functionality. This document analyzes whether to use it for our project or implement custom authentication.

## Serverpod Auth Module Capabilities

### What serverpod_auth Provides

**Out-of-the-Box Features:**
- Email/Password authentication
- Google Sign-In integration
- Apple Sign-In integration  
- Firebase authentication
- User management (username, profile pictures)
- Session handling with JWT tokens
- Database schema for users and sessions
- Authentication middleware

**Integration Points:**
```yaml
# Server-side
dependencies:
  serverpod_auth_server: ^2.5.0+

# Client-side  
dependencies:
  serverpod_auth_client: ^2.5.0+
```

**Setup Steps:**
1. Add dependencies to server and client pubspec
2. Configure authentication handler in server.dart
3. Run `serverpod generate` to create client code
4. Create and apply database migrations
5. Set up SessionManager in Flutter app

### Serverpod Auth Architecture

```
serverpod_auth/
├── User Management
│   ├── Email/password storage
│   ├── Social provider linking
│   ├── Profile management
│   └── User search
├── Session Management
│   ├── JWT token generation
│   ├── Token refresh
│   ├── Session tracking
│   └── Device management
└── Authentication Methods
    ├── Email + Password
    ├── Google OAuth
    ├── Apple OAuth
    └── Firebase Auth
```

## Project Requirements vs. serverpod_auth

### Our Requirements (Story 1-1: Email OTP Authentication)

| Requirement | serverpod_auth Support | Custom Required |
|------------|------------------------|-----------------|
| **Email OTP (One-Time Password)** | ❌ No - only email/password | ✅ Yes |
| **SMS OTP** | ❌ No | ✅ Yes |
| **Cryptographically secure OTP with salts** | ❌ No OTP support | ✅ Yes |
| **Multi-layer rate limiting (per-ID, per-IP, global)** | ❌ Basic only | ✅ Yes |
| **Progressive account lockout (5/30/60/1440 min)** | ❌ No | ✅ Yes |
| **RS256 JWT with device binding** | ⚠️ Partial - JWT yes, RS256/binding unclear | ✅ Yes |
| **Refresh token rotation with reuse detection** | ⚠️ Partial - rotation unclear | ✅ Yes |
| **Token blacklisting with Redis** | ❌ No | ✅ Yes |
| **AES-256-GCM client-side encryption** | ❌ No | ✅ Yes |
| **Unified viewer/maker authentication** | ✅ Yes | N/A |
| **Google/Apple social login** | ✅ Yes (Story 1-2) | N/A |

### Key Gaps

**Critical Missing Features:**
1. **No OTP Support:** serverpod_auth uses password-based auth, not OTP
2. **Limited Rate Limiting:** No multi-layer or Redis-based rate limiting
3. **No Account Lockout:** No progressive lockout mechanism
4. **Security Controls:** Unclear if RS256, device binding, token rotation supported
5. **No Token Blacklisting:** No built-in token revocation/blacklist system

**What We Can Use:**
- Social login integration (Google, Apple) for Story 1-2
- Basic user/session schema as reference
- Session management patterns

## Architectural Decision

### Decision: Custom Authentication with Selective serverpod_auth Integration

**Rationale:**
1. **OTP Requirement:** Core requirement not supported by serverpod_auth
2. **Security Requirements:** Story mandates specific security controls (SEC-001, SEC-003) that exceed serverpod_auth capabilities
3. **Rate Limiting:** Multi-layer Redis-based rate limiting required
4. **Account Protection:** Progressive lockout mechanism required
5. **Compliance:** Need specific audit trails and security monitoring

### Implementation Strategy

**Phase 1: Custom OTP Authentication (Story 1-1)** ✅ CURRENT
- Custom OTP generation with SHA-256 + salts
- Redis-based multi-layer rate limiting
- Progressive account lockout mechanism
- RS256 JWT with device binding
- Refresh token rotation with reuse detection
- Token blacklisting service
- AES-256-GCM secure storage

**Phase 2: Social Login Integration (Story 1-2)** 🔮 FUTURE
- **Option A:** Integrate serverpod_auth for social login only
- **Option B:** Use provider SDKs directly with our custom session system
- **Decision:** Evaluate in Story 1-2 based on integration complexity

**Phase 3: Unified Session Management (Story 1-3)**
- Extend custom session system to support both OTP and social logins
- Implement consistent refresh token rotation across all auth methods
- Unified session tracking and device management

## Custom Implementation Architecture

### Database Schema
```sql
-- Users table (custom)
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50) UNIQUE,
  role VARCHAR(50) DEFAULT 'viewer',
  auth_provider VARCHAR(50) DEFAULT 'email',
  failed_attempts INT DEFAULT 0,
  locked_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- OTPs table (custom)
CREATE TABLE otps (
  id BIGSERIAL PRIMARY KEY,
  identifier VARCHAR(255),
  otp_hash VARCHAR(255),  -- SHA-256(OTP + salt)
  salt VARCHAR(255),
  attempts INT DEFAULT 0,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Sessions table (custom with enhancements)
CREATE TABLE sessions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  access_token VARCHAR(500),
  refresh_token VARCHAR(500),
  device_id VARCHAR(255),
  ip_address VARCHAR(45),
  is_revoked BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Token blacklist (custom)
CREATE TABLE token_blacklist (
  id BIGSERIAL PRIMARY KEY,
  token_id VARCHAR(255),
  user_id BIGINT,
  reason VARCHAR(100),
  expires_at TIMESTAMP,
  blacklisted_at TIMESTAMP DEFAULT NOW()
);
```

### Services Architecture
```
video_window_server/lib/src/
├── endpoints/identity/
│   └── auth_endpoint.dart        # OTP send/verify, social login, refresh
├── services/auth/
│   ├── otp_service.dart          # Cryptographic OTP generation
│   ├── rate_limit_service.dart   # Redis multi-layer rate limiting
│   ├── lockout_service.dart      # Progressive account lockout
│   ├── jwt_service.dart          # RS256 token generation/validation
│   ├── token_rotation_service.dart # Refresh token rotation
│   └── token_blacklist_service.dart # Token revocation
└── middleware/
    ├── auth_middleware.dart      # JWT validation
    └── rate_limit_middleware.dart # Request rate limiting
```

## Migration Path

### If We Later Want to Adopt serverpod_auth

**Scenario:** After implementing custom OTP auth, we want to add serverpod_auth for social logins.

**Migration Strategy:**
1. Keep custom OTP system as-is (serverpod_auth doesn't conflict)
2. Add serverpod_auth_server dependency
3. Map serverpod_auth users table to our custom users table
4. Use serverpod_auth only for Google/Apple OAuth flows
5. Maintain unified session management in our custom system
6. Both systems write to the same users/sessions tables

**Database Alignment:**
```sql
-- Ensure our users table is compatible with serverpod_auth
ALTER TABLE users ADD COLUMN IF NOT EXISTS user_info_id BIGINT;  -- For serverpod_auth
ALTER TABLE users ADD COLUMN IF NOT EXISTS user_images_id BIGINT; -- For serverpod_auth
```

## References

- [Serverpod Authentication Documentation](https://docs.serverpod.dev/2.5.0/concepts/authentication/setup)
- [Serverpod Auth GitHub](https://github.com/serverpod/serverpod/tree/main/modules/serverpod_auth)
- Story 1-1: Email OTP Authentication (this story)
- Story 1-2: Social Login Integration (future)
- Security Research: `security/story-1.1-authentication-security-research.md`

## Conclusion

**Decision:** Implement custom authentication for OTP-based flows. Consider serverpod_auth integration for social logins in Story 1-2.

**Justification:**
- OTP authentication is a hard requirement not supported by serverpod_auth
- Security requirements (SEC-001, SEC-003) mandate specific implementations
- Custom implementation gives us full control over rate limiting, lockout, and audit trails
- Social login integration can potentially leverage serverpod_auth in future stories

**Trade-offs:**
- ✅ Full control over security features
- ✅ Meets all story acceptance criteria
- ✅ Flexible for future enhancements
- ❌ More code to maintain
- ❌ Can't leverage serverpod_auth updates for OTP (not applicable)

**Next Steps:**
1. Complete custom OTP implementation (Story 1-1)
2. Evaluate serverpod_auth for social login (Story 1-2)
3. Document integration patterns if we adopt hybrid approach

