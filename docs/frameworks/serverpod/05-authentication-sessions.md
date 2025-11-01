# Serverpod Authentication & Sessions

**Version:** Serverpod 2.9.x  
**Project:** Video Window  
**Last Updated:** 2025-10-30

---

## Overview

Serverpod provides built-in session management. Video Window uses JWT tokens with secure storage for authentication.

---

## Authentication Flow

### Sign-In Process

```
User enters email → Generate OTP → Send via email
   ↓
User enters OTP → Verify OTP → Create session
   ↓
Return JWT token → Store securely → Authenticated
```

---

## Server-Side Implementation

### 1. Auth Endpoint

```dart
// endpoints/identity/auth_endpoint.dart
import 'package:serverpod/serverpod.dart';

class AuthEndpoint extends Endpoint {
  @override
  String get name => 'identity.auth';
  
  /// Generate OTP and send via email
  Future<OtpResponse> requestOtp(
    Session session,
    String email,
  ) async {
    // Validate email format
    if (!EmailValidator.isValid(email)) {
      throw InvalidEmailException();
    }
    
    // Rate limiting check
    await _checkRateLimit(session, email);
    
    // Generate cryptographically secure OTP
    final otp = _generateSecureOtp();
    
    // Store OTP with 5-minute expiry
    await session.db.insert(OtpRecord(
      email: email,
      otpHash: _hashOtp(otp),
      expiresAt: DateTime.now().add(Duration(minutes: 5)),
      attempts: 0,
    ));
    
    // Send email (async)
    await EmailService.sendOtp(email, otp);
    
    return OtpResponse(success: true);
  }
  
  /// Verify OTP and create session
  Future<AuthResponse> signInWithOtp(
    Session session,
    String email,
    String otp,
  ) async {
    // Fetch OTP record
    final otpRecord = await session.db.findFirstWhere<OtpRecord>(
      where: (t) => t.email.equals(email),
    );
    
    if (otpRecord == null) {
      throw OtpNotFoundException();
    }
    
    // Check expiry
    if (otpRecord.expiresAt.isBefore(DateTime.now())) {
      throw OtpExpiredException();
    }
    
    // Check attempts (max 3)
    if (otpRecord.attempts >= 3) {
      throw TooManyAttemptsException();
    }
    
    // Verify OTP
    if (!_verifyOtp(otp, otpRecord.otpHash)) {
      await _incrementAttempts(session, otpRecord);
      throw InvalidOtpException();
    }
    
    // Find or create user
    var user = await session.db.findFirstWhere<User>(
      where: (t) => t.email.equals(email),
    );
    
    if (user == null) {
      user = await session.db.insert(User(
        email: email,
        role: UserRole.viewer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    
    // Create session
    final authKey = await session.auth.signInUser(
      user.id!,
      'email_otp',
    );
    
    // Delete used OTP
    await session.db.deleteWhere<OtpRecord>(
      where: (t) => t.email.equals(email),
    );
    
    return AuthResponse(
      token: authKey,
      user: user,
    );
  }
  
  /// Sign out
  Future<void> signOut(Session session) async {
    await session.auth.signOutUser();
  }
  
  // Helper methods
  String _generateSecureOtp() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }
  
  String _hashOtp(String otp) {
    // Use bcrypt or similar
    return BCrypt.hashpw(otp, BCrypt.gensalt());
  }
  
  bool _verifyOtp(String otp, String hash) {
    return BCrypt.checkpw(otp, hash);
  }
}
```

---

## Client-Side Implementation (Flutter)

### 1. Setup Authentication Key Manager

```dart
import 'package:video_window_client/video_window_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureAuthKeyManager extends AuthenticationKeyManager {
  final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  static const _keyTokens = 'auth_tokens';
  
  @override
  Future<String?> get() async {
    return await _storage.read(key: _keyTokens);
  }
  
  @override
  Future<void> put(String key) async {
    await _storage.write(key: _keyTokens, value: key);
  }
  
  @override
  Future<void> remove() async {
    await _storage.delete(key: _keyTokens);
  }
}
```

### 2. Initialize Client

```dart
final client = Client(
  'http://localhost:8080/',
  authenticationKeyManager: SecureAuthKeyManager(),
);
```

### 3. Sign In Flow

```dart
class AuthService {
  final Client client;
  
  AuthService(this.client);
  
  /// Request OTP
  Future<void> requestOtp(String email) async {
    try {
      await client.identity.auth.requestOtp(email);
    } on InvalidEmailException {
      throw 'Invalid email format';
    } on RateLimitException {
      throw 'Too many attempts. Try again later.';
    }
  }
  
  /// Verify OTP and sign in
  Future<User> signInWithOtp(String email, String otp) async {
    try {
      final response = await client.identity.auth.signInWithOtp(email, otp);
      return response.user;
    } on InvalidOtpException {
      throw 'Invalid OTP code';
    } on OtpExpiredException {
      throw 'OTP expired. Request a new one.';
    } on TooManyAttemptsException {
      throw 'Too many failed attempts. Try again later.';
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    await client.identity.auth.signOut();
  }
  
  /// Check if authenticated
  Future<bool> isAuthenticated() async {
    final key = await client.authenticationKeyManager?.get();
    return key != null && key.isNotEmpty;
  }
}
```

---

## Session Management

### Accessing Current User

```dart
// In any endpoint
class StoryEndpoint extends Endpoint {
  Future<List<Story>> getMyStories(Session session) async {
    // Get authenticated user
    final authInfo = await session.auth.authenticatedInfo;
    
    if (authInfo == null) {
      throw UnauthorizedException();
    }
    
    final userId = authInfo.userId;
    
    // Fetch user's stories
    return await session.db.find<Story>(
      where: (t) => t.makerId.equals(userId),
    );
  }
}
```

### Requiring Authentication

```dart
class ProtectedEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;  // Enforces authentication
  
  Future<void> doSomething(Session session) async {
    // User is guaranteed to be authenticated here
    final userId = (await session.auth.authenticatedInfo)!.userId;
  }
}
```

---

## Token Refresh

### Auto-Refresh Strategy

```dart
class RefreshAuthKeyManager extends SecureAuthKeyManager {
  final Client client;
  
  RefreshAuthKeyManager(this.client);
  
  @override
  Future<String?> get() async {
    final token = await super.get();
    
    if (token != null && _isTokenExpiringSoon(token)) {
      // Refresh token
      final newToken = await client.identity.auth.refreshToken();
      await put(newToken);
      return newToken;
    }
    
    return token;
  }
  
  bool _isTokenExpiringSoon(String token) {
    // JWT expiry check logic
    final payload = _parseJwt(token);
    final exp = payload['exp'] as int;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();
    return expiryTime.difference(now).inMinutes < 5;
  }
}
```

---

## Security Best Practices

### 1. Rate Limiting

```dart
Future<void> _checkRateLimit(Session session, String email) async {
  final recentAttempts = await session.db.count<OtpRequest>(
    where: (t) => 
      t.email.equals(email) &
      t.createdAt.after(DateTime.now().subtract(Duration(hours: 1))),
  );
  
  if (recentAttempts >= 5) {
    throw RateLimitException();
  }
}
```

### 2. Account Lockout

```dart
Future<void> _checkAccountLockout(Session session, String email) async {
  final user = await session.db.findFirstWhere<User>(
    where: (t) => t.email.equals(email),
  );
  
  if (user?.lockedUntil != null && 
      user!.lockedUntil!.isAfter(DateTime.now())) {
    throw AccountLockedException();
  }
}
```

### 3. Secure Token Storage

```dart
// ✅ GOOD - Secure storage
final _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

// ❌ BAD - SharedPreferences (unencrypted)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('token', token);  // INSECURE!
```

---

## Troubleshooting

### Issue: "Session expired"
**Solution:** Implement token refresh
```dart
try {
  await client.someEndpoint.call();
} on SessionExpiredException {
  await authService.refreshToken();
  // Retry
}
```

### Issue: "Unauthorized"
**Solution:** Check token storage
```dart
final token = await client.authenticationKeyManager?.get();
print('Stored token: $token');
```

---

## Related Documentation

- **Setup:** [01-setup-installation.md](./01-setup-installation.md)
- **Code Generation:** [03-code-generation.md](./03-code-generation.md)
- **Deployment:** [06-deployment.md](./06-deployment.md)

---

**Key Takeaway:** Use Serverpod's built-in session management with secure token storage and proper error handling.
