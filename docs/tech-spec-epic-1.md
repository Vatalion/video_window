# Epic 1: Viewer Authentication & Session Handling - Technical Specification

**Epic Goal:** Provide secure authentication and session management for viewers and makers using email OTP and social login with robust session refresh and account recovery capabilities.

**Stories:**
- 1.1: Email OTP Authentication
- 1.2: Social Login Integration (Google, Apple)
- 1.3: Session Management & Refresh
- 1.4: Account Recovery (Email only)

## Architecture Overview

### Component Mapping
- **Flutter App:** Auth Module (login forms, session storage, social login widgets)
- **Serverpod:** Identity Service (authentication, session management, user data)
- **Database:** Users table, sessions table, verification tokens
- **External:** Email provider (SendGrid), Social OAuth providers (Google, Apple)

### Technology Stack
- **Flutter 3.19.6:** `flutter_secure_storage` 9.2.2, `google_sign_in` 6.2.1, `sign_in_with_apple` 6.1.1, `dio` 5.7.0 for API transport
- **Serverpod 2.9.2:** Identity and session endpoints in `video_window_server/lib/src/endpoints/identity/`
- **Email Delivery:** SendGrid API v3 via `sendgrid-dart` 7.12.0 for transactional OTP messages
- **Cryptography:** `bcrypt` 4.0.1 for OTP hashing, `package:jwt` 3.0.1 with RS256 signing using managed key pairs
- **Data Stores:** PostgreSQL 15 primary database, Redis 7.2.4 for rate limiting and token blacklist caches
- **Secrets Management:** 1Password Connect 1.7.3 vault `video-window-auth` providing runtime secrets injection during deployment

## Data Models

### User Entity
```dart
class User {
  final String id;
  final String email;
  final String? phone;
  final AuthProvider authProvider;
  final List<UserRole> roles;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum AuthProvider { email, google, apple }
enum UserRole { viewer, maker, admin }
```

### Session Entity
```dart
class Session {
  final String id;
  final String userId;
  final String token;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String deviceInfo;
  final String ipAddress;
}
```

### Authentication Request/Response
```dart
class LoginRequest {
  final String email;
  final String otp;
  final String deviceInfo;
}

class LoginResponse {
  final User user;
  final Session session;
  final String refreshToken;
}
```

## API Endpoints

### Authentication Endpoints
```
POST /auth/email/send-otp
POST /auth/email/verify-otp
POST /auth/google/login
POST /auth/apple/login
POST /auth/refresh
POST /auth/logout
POST /auth/recovery/send
POST /auth/recovery/verify
```

### Endpoint Specifications

#### Send Email OTP
```dart
// Request
{
  "email": "user@example.com"
}

// Response
{
  "success": true,
  "message": "OTP sent successfully",
  "expiresIn": 300
}
```

#### Verify OTP and Login
```dart
// Request
{
  "email": "user@example.com",
  "otp": "123456",
  "deviceInfo": "iPhone 15 Pro"
}

// Response
{
  "user": { ... },
  "session": { ... },
  "refreshToken": "refresh_token_here"
}
```

## Implementation Details

### Flutter Auth Module Structure

#### Authentication Flow
1. **Email Login:** User enters email → OTP sent → User enters OTP → Validate → Create session
2. **Social Login:** User selects provider → OAuth flow → Get user info → Create/update user → Create session
3. **Session Refresh:** Background token refresh before expiration → Update secure storage
4. **Logout:** Clear local storage → Invalidate server session → Navigate to login

#### State Management (BLoC)
```dart
// Auth Events
abstract class AuthEvent {}
class LoginWithEmailRequested extends AuthEvent {
  final String email;
}
class OtpVerificationRequested extends AuthEvent {
  final String email;
  final String otp;
}
class SocialLoginRequested extends AuthEvent {
  final AuthProvider provider;
}
class SessionRefreshRequested extends AuthEvent {}
class LogoutRequested extends AuthEvent {}

// Auth States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
}
class AuthUnauthenticated extends AuthState {
  final String? error;
}
```

#### Secure Storage Implementation
```dart
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveTokens(LoginResponse response) async {
    await _storage.write(key: 'access_token', value: response.session.token);
    await _storage.write(key: 'refresh_token', value: response.refreshToken);
    await _storage.write(key: 'user_id', value: response.user.id);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}
```

### Serverpod Identity Service

#### Authentication Service
```dart
class AuthService {
  // Email OTP generation and validation
  Future<String> generateOtp(String email) async {
    final otp = _generateSixDigitCode();
    final hashedOtp = _hashOtp(otp);

    await _otpRepository.storeOtp(email, hashedOtp, DateTime.now().add(10.minutes));
    await _emailService.sendOtpEmail(email, otp);

    return otp; // For development only
  }

  // OTP verification
  Future<LoginResponse> verifyOtp(String email, String otp, String deviceInfo) async {
    final storedOtp = await _otpRepository.getValidOtp(email);
    if (storedOtp == null || !_verifyOtpHash(otp, storedOtp.hashedOtp)) {
      throw AuthException('Invalid or expired OTP');
    }

    let user = await _userRepository.findByEmail(email);
    if (user == null) {
      user = await _createUser(email, AuthProvider.email);
    }

    final session = await _createSession(user.id, deviceInfo);
    await _otpRepository.markOtpUsed(storedOtp.id);

    return LoginResponse(
      user: user,
      session: session,
      refreshToken: _generateRefreshToken(user.id),
    );
  }

  // Social login handler
  Future<LoginResponse> handleSocialLogin(
    String providerId,
    AuthProvider provider,
    String deviceInfo
  ) async {
    // Verify provider token with respective service
    final userInfo = await _verifySocialToken(providerId, provider);

    let user = await _userRepository.findByProviderId(providerId, provider);
    if (user == null) {
      user = await _createUserFromSocial(userInfo, provider);
    }

    final session = await _createSession(user.id, deviceInfo);

    return LoginResponse(
      user: user,
      session: session,
      refreshToken: _generateRefreshToken(user.id),
    );
  }
}
```

#### Session Management
```dart
class SessionService {
  // Session creation with JWT
  Future<Session> createSession(String userId, String deviceInfo) async {
    final user = await _userRepository.findById(userId);
    final claims = {
      'sub': user.id,
      'email': user.email,
      'roles': user.roles.map((r) => r.name).toList(),
      'exp': DateTime.now().add(15.minutes).millisecondsSinceEpoch ~/ 1000,
    };

    final token = _generateJwt(claims);

    return await _sessionRepository.create(
      userId: userId,
      token: token,
      expiresAt: DateTime.now().add(15.minutes),
      deviceInfo: deviceInfo,
      ipAddress: _getClientIpAddress(),
    );
  }

  // Session refresh
  Future<Session> refreshSession(String refreshToken) async {
    final claims = _verifyRefreshToken(refreshToken);
    final userId = claims['sub'] as String;

    // Validate refresh token hasn't been revoked
    if (!await _refreshTokenRepository.isValid(refreshToken, userId)) {
      throw AuthException('Invalid refresh token');
    }

    final user = await _userRepository.findById(userId);
    final newSession = await createSession(userId, claims['deviceInfo'] as String);

    // Revoke old refresh token
    await _refreshTokenRepository.revoke(refreshToken);

    return newSession;
  }
}
```

## Security Implementation

### JWT Token Structure
```dart
// Access Token Claims
{
  "sub": "user_id",
  "email": "user@example.com",
  "roles": ["viewer"],
  "iat": 1697049600,
  "exp": 1697050500
}

// Refresh Token Claims
{
  "sub": "user_id",
  "type": "refresh",
  "deviceInfo": "iPhone 15 Pro",
  "iat": 1697049600,
  "exp": 1699382400 // 30 days
}
```

### OTP Security
- 6-digit numeric codes
- 10-minute expiration
- Rate limiting: 3 attempts per email per 15 minutes
- Hashed storage using bcrypt
- Single-use tokens (marked as used after successful verification)

### Social OAuth Integration
```dart
// Google Sign-In Configuration (OAuth client: video-window-auth-mobile)
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  clientId: '59605983206-k9g2videowindowauth.apps.googleusercontent.com',
);

// Apple Sign-In Configuration (Service ID: com.videowindow.auth)
final AppleSignIn _appleSignIn = AppleSignIn(
  scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
);
```

## Source Tree & File Directives

| Path | Action | Notes |
| --- | --- | --- |
| `video_window_flutter/packages/features/auth/lib/presentation/pages/email_otp_page.dart` | create | Flutter UI for Story 1.1 email OTP entry (ties to AC1) |
| `video_window_flutter/packages/features/auth/lib/presentation/widgets/social_sign_in_buttons.dart` | create | Shared widget for Story 1.2, consumes design tokens |
| `video_window_flutter/packages/features/auth/lib/presentation/bloc/auth_bloc.dart` | modify | Extend events/state for OTP, social login, refresh (Stories 1.1–1.3) |
| `video_window_flutter/packages/features/auth/lib/use_cases/request_email_otp_use_case.dart` | create | Invokes core repository for OTP dispatch |
| `video_window_flutter/packages/core/lib/data/repositories/auth_repository.dart` | modify | Add OTP, social login, session refresh methods |
| `video_window_flutter/packages/core/lib/data/services/auth/otp_service.dart` | create | Rate-limited OTP API client |
| `video_window_flutter/packages/core/lib/data/services/auth/session_service.dart` | create | Handles refresh token exchange |
| `video_window_server/lib/src/endpoints/identity/otp_endpoint.dart` | modify | Expose `sendOtp`/`verifyOtp` Serverpod endpoints |
| `video_window_server/lib/src/endpoints/identity/social_auth_endpoint.dart` | create | Apple/Google token verification + reconciliation |
| `video_window_server/lib/src/services/session_service.dart` | modify | Implement refresh rotation & device binding |
| `video_window_server/lib/src/services/recovery_service.dart` | create | Email recovery logic for Story 1.4 |
| `video_window_server/migrations/2025-10-29T00-otp-session-refresh.sql` | create | Adds indexes and refresh token table referenced in Database Migrations |
| `video_window_flutter/packages/features/auth/test/presentation/bloc/auth_bloc_test.dart` | modify | Extend coverage for new events (≥80%) |
| `video_window_flutter/packages/features/auth/test/presentation/widgets/social_sign_in_buttons_test.dart` | create | Widget contract tests |
| `video_window_flutter/packages/features/auth/test/use_cases/session_refresh_use_case_test.dart` | create | Validates session refresh logic |
| `docs/stories/1.3.session-management-and-refresh.md` | create | Story for session lifecycle (fills validation gap) |
| `docs/stories/1.4.account-recovery-email-only.md` | create | Story for account recovery flow |
| `docs/bmm-workflow-status.md` | create | Captures workflow status for BMM integration |
| `docs/tech-spec.md` | create | Aggregated tech spec index (required output) |

## Implementation Guide

### Step-by-Step Flow Alignment
1. **Client Authentication UX** (Stories 1.1 & 1.2)
  - Build OTP and social login screens (`email_otp_page.dart`, `social_sign_in_buttons.dart`).
  - Connect screens to `AuthBloc` events; ensure analytics hooks defined in `analytics/auth_events.dart`.
2. **Server Authentication Services** (Stories 1.1, 1.2 & 1.3)
  - Implement OTP, social, and refresh endpoints in Serverpod identity module.
  - Enforce Redis-backed rate limiting and refresh token rotation per `session_service.dart`.
3. **Session Lifecycle Management** (Story 1.3)
  - Add background refresh scheduler in `session_service.dart` client to renew tokens 5 minutes before expiry.
  - Persist device binding metadata and revoke reused refresh tokens with blacklist entry.
4. **Account Recovery** (Story 1.4)
  - Implement recovery email dispatch and verification flows in `recovery_service.dart`.
  - Surface UI entry points under `AccountRecoveryPage` with secure token verification and password reset fallback.
5. **Testing & Verification**
  - Run `melos run test:unit` for auth package coverage and `melos run test:integration` for Serverpod flows.
  - Security tests target OTP brute force, refresh replay, and recovery token misuse using `integration/security/auth_security_test.dart`.

## Test Traceability

Traceability ensures every acceptance criterion is backed by an implementation artifact and an automated/observable check. Refer to `docs/analytics/authentication-dashboard.md` for live metrics and `docs/runbooks/authentication.md` for operational procedures.
| Acceptance Criterion | Implementation Artifact | Test Coverage |
| --- | --- | --- |
| OTP flow with rate limiting (Story 1.1 AC1) | `otp_endpoint.dart`, `request_email_otp_use_case.dart` | `auth_bloc_test.dart` (unit), `otp_flow_integration_test.dart` |
| Secure token storage (Story 1.1 AC2) | `session_service.dart`, secure storage wrappers | `secure_storage_test.dart`, `session_refresh_use_case_test.dart` |
| Social login integration (Story 1.2 AC1/AC2) | `social_auth_endpoint.dart`, `social_sign_in_buttons.dart` | `social_auth_integration_test.dart`, `social_sign_in_buttons_test.dart` |
| Session refresh (Story 1.3 AC1/AC2) | `SessionService.refreshSession`, background scheduler | `session_refresh_use_case_test.dart`, `session_refresh_integration_test.dart` |
| Account recovery (Story 1.4 AC1/AC2) | `recovery_service.dart`, `AccountRecoveryPage` | `account_recovery_flow_test.dart`, `recovery_service_test.dart` |

### Toolchain & Automation
- CI pipeline: `melos run analyze`, `melos run test`, `melos run format` enforced pre-merge.
- Security automation: weekly dependency audit via `melos run audit:security` (adds `snyk` scan for auth services).
- Deployment: Serverpod migrations executed with `serverpod migrate --apply` referencing migration file above.

## Testing Strategy

### Unit Tests
- **Auth BLoC:** Test all state transitions and edge cases
- **Secure Storage:** Test token encryption/decryption
- **Service Layer:** Mock external dependencies and test business logic
- **OTP Generation:** Test uniqueness, expiration, and validation

### Integration Tests
- **Authentication Flow:** End-to-end login flows with test database
- **Social Login:** Mock OAuth providers and test user creation/update
- **Session Refresh:** Test automatic token refresh scenarios
- **Error Handling:** Test network failures, invalid tokens, expired sessions

### Security Tests
- **Token Validation:** Test JWT creation, verification, and expiration
- **OTP Security:** Test rate limiting, expiration, and replay protection
- **Secure Storage:** Test encryption key management and data protection
- **Session Hijacking:** Test session invalidation and device tracking

## Error Handling

### Error Types
```dart
abstract class AuthException implements Exception {
  final String message;
  final AuthErrorCode code;
}

class InvalidCredentialsException extends AuthException { }
class AccountLockedException extends AuthException { }
class SessionExpiredException extends AuthException { }
class NetworkException extends AuthException { }
```

### Error Recovery
- **Network Errors:** Automatic retry with exponential backoff
- **Session Expiration:** Automatic refresh attempt, fallback to login
- **Invalid OTP:** Clear input, show error message, enable resend
- **Social Login Errors:** Fallback to email login, clear error messaging

## Performance Considerations

### Client Optimizations
- Lazy loading of auth forms
- Cached user profile data
- Background session refresh (5 minutes before expiration)
- Optimized images for social login buttons

### Server Optimizations
- Database indexes on email, user ID, and provider ID
- Redis caching for frequently accessed user data
- Connection pooling for database operations
- Asynchronous email sending

## Monitoring and Analytics

### Key Metrics
- Login success rate by provider
- OTP generation and verification rates
- Session refresh frequency and success rate
- Authentication error rates and types
- Social login conversion rates

### Logging Strategy
- Structured JSON logs with correlation IDs
- Security events (failed logins, account lockouts)
- Performance metrics (authentication latency)
- User behavior analytics (login patterns, device usage)

## Deployment Considerations

### Environment Configuration

| Variable | Secret Store | Description |
| -------- | ------------ | ----------- |
| `OTP_SECRET_KEY` | `vault://video-window/auth/otp_secret_key` | HMAC secret for OTP hashing and validation |
| `JWT_PRIVATE_KEY_PEM` | `vault://video-window/auth/jwt_private_key` | RS256 private key used to sign access tokens |
| `JWT_PUBLIC_KEY_PEM` | `vault://video-window/auth/jwt_public_key` | RS256 public key distributed to Serverpod clients for validation |
| `GOOGLE_CLIENT_ID` | `vault://video-window/auth/google_client_id` | OAuth client ID provisioned in Google Cloud |
| `GOOGLE_CLIENT_SECRET` | `vault://video-window/auth/google_client_secret` | OAuth client secret for Google Sign-In |
| `APPLE_TEAM_ID` | `vault://video-window/auth/apple_team_id` | Apple developer team identifier for Sign in with Apple |
| `APPLE_KEY_ID` | `vault://video-window/auth/apple_key_id` | Key ID for Apple Sign in private key |
| `APPLE_PRIVATE_KEY_P8` | `vault://video-window/auth/apple_private_key` | Private key file for Sign in with Apple JWT generation |
| `SENDGRID_API_KEY` | `vault://video-window/auth/sendgrid_api_key` | Transactional email API key used for OTP and recovery emails |
| `REDIS_URL` | `vault://video-window/shared/redis_url` | Redis connection string for rate limiting and token caches |

All secrets are rotated quarterly and injected at deploy time through 1Password Connect 1.7.3.

### Database Migrations
```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  auth_provider VARCHAR(50) NOT NULL DEFAULT 'email',
  google_id VARCHAR(255),
  apple_id VARCHAR(255),
  roles JSONB DEFAULT '["viewer"]',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Sessions table
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  device_info JSONB,
  ip_address INET,
  created_at TIMESTAMP DEFAULT NOW()
);

-- OTP table
CREATE TABLE otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL,
  code_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  is_used BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Recovery tokens table
CREATE TABLE recovery_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  issued_ip INET,
  issued_user_agent VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_provider_id ON users(google_id) WHERE google_id IS NOT NULL;
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_otp_codes_email ON otp_codes(email) WHERE is_used = false;
CREATE INDEX idx_recovery_tokens_user_id ON recovery_tokens(user_id);
CREATE INDEX idx_recovery_tokens_expires_at ON recovery_tokens(expires_at);
```

## Success Criteria

### Functional Requirements
- ✅ Users can authenticate using email OTP
- ✅ Users can authenticate using Google/Apple social login
- ✅ Sessions are automatically refreshed before expiration
- ✅ Users can recover accounts using email
- ✅ Secure token storage on client devices
- ✅ Authentication completes within 3 seconds
- ✅ Session refresh completes within 1 second
- ✅ All authentication data encrypted at rest
- ✅ Rate limiting prevents abuse
- ✅ Comprehensive audit logging

### Success Metrics
- Login success rate > 95%
- Average authentication time < 3 seconds
- Zero security vulnerabilities in penetration testing
- Session refresh success rate > 99%
- User satisfaction score > 4.5/5

## Next Steps

1. **Implement Flutter Auth Module** - BLoC, UI components, secure storage
2. **Develop Serverpod Identity Service** - Authentication logic, session management
3. **Configure External Services** - SendGrid, OAuth providers (Google, Apple)
4. **Implement Security Measures** - JWT handling, OTP security, rate limiting
5. **Comprehensive Testing** - Unit, integration, and security testing
6. **Performance Optimization** - Caching, database optimization, monitoring framework

---

**Version:** v1.0 (Definitive)
**Date:** 2025-10-29
**Dependencies:** Epic 01 (Environment & CI/CD) for repository structure and secrets management
**Blocks:** Epic 2 (Maker Auth), Epic 3 (Profile Management), Epic 9 (Offers), Epic 12 (Checkout)