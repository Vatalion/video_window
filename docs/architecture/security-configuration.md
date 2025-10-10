# Craft Video Marketplace Security Configuration

## Overview

This document outlines the comprehensive security architecture and configuration requirements for the Craft Video Marketplace MVP, addressing all NFR security requirements from the PRD.

## Security Architecture Principles

1. **Defense in Depth** - Multiple layers of security controls
2. **Least Privilege** - Minimum access required for functionality
3. **Zero Trust** - Verify everything, trust nothing implicitly
4. **Secure by Default** - Security enabled by default, not opt-in

## 1. Infrastructure Security

### 1.1 Network Security

```yaml
# Network Security Groups (AWS)
vpc_security_groups:
  web_tier:
    ingress:
      - port: 443
        protocol: tcp
        source: 0.0.0.0/0
      - port: 80
        protocol: tcp
        source: 0.0.0.0/0
        description: "HTTP to HTTPS redirect"
    egress:
      - port: 443
        protocol: tcp
        destination: 0.0.0.0/0
        description: "HTTPS outbound"

  app_tier:
    ingress:
      - port: 8080
        protocol: tcp
        source: web_tier_security_group
      - port: 5432
        protocol: tcp
        source: app_tier_security_group
    egress:
      - port: 443
        protocol: tcp
        destination: 0.0.0.0/0
      - port: 587
        protocol: tcp
        destination: email_service_ips

  database_tier:
    ingress:
      - port: 5432
        protocol: tcp
        source: app_tier_security_group
    egress: []
```

### 1.2 SSL/TLS Configuration

```nginx
# Nginx SSL Configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_stapling on;
ssl_stapling_verify on;

# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

## 2. Application Security

### 2.1 Authentication & Authorization

#### JWT Token Configuration

```dart
// lib/core/security/jwt_config.dart
class JWTConfig {
  static const Duration accessTokenExpiry = Duration(minutes: 15);
  static const Duration refreshTokenExpiry = Duration(days: 7);
  static const String algorithm = 'RS256';

  // Token claims structure
  static Map<String, dynamic> standardClaims = {
    'iss': 'craft-marketplace',
    'aud': 'craft-users',
    'sub': '', // User ID
    'exp': '', // Expiration timestamp
    'iat': '', // Issued at timestamp
    'jti': '', // JWT ID for revocation
    'scope': [], // User permissions
    'role': '', // viewer, maker, admin
    'device_id': '', // For session management
  };
}
```

#### Role-Based Access Control (RBAC)

```dart
// lib/core/security/rbac.dart
enum Permission {
  // Viewer permissions
  viewFeed,
  viewStory,
  submitOffer,
  placeBid,
  makePayment,
  viewOrders,

  // Maker permissions
  createStory,
  editOwnStory,
  publishStory,
  manageAuctions,
  acceptBids,
  manageOrders,
  viewAnalytics,

  // Admin permissions
  moderateContent,
  manageUsers,
  viewAllAnalytics,
  systemConfiguration,
}

class Role {
  final String name;
  final Set<Permission> permissions;

  const Role(this.name, this.permissions);
}

class Roles {
  static const viewer = Role('viewer', {
    Permission.viewFeed,
    Permission.viewStory,
    Permission.submitOffer,
    Permission.placeBid,
    Permission.makePayment,
    Permission.viewOrders,
  });

  static const maker = Role('maker', {
    ...viewer.permissions,
    Permission.createStory,
    Permission.editOwnStory,
    Permission.publishStory,
    Permission.manageAuctions,
    Permission.acceptBids,
    Permission.manageOrders,
    Permission.viewAnalytics,
  });

  static const admin = Role('admin', {
    ...maker.permissions,
    Permission.moderateContent,
    Permission.manageUsers,
    Permission.viewAllAnalytics,
    Permission.systemConfiguration,
  });
}
```

### 2.2 Data Encryption

#### Encryption at Rest

```dart
// lib/core/security/encryption.dart
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  static final algorithm = AesGcm.with256bits();
  static final keyDerivation = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  // Encrypt sensitive data
  static Future<SecretBox> encrypt(String plaintext, String password) async {
    final secretKey = await keyDerivation.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: utf8.encode('craft-marketplace-salt'),
    );

    return await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
    );
  }

  // Database field encryption
  static Map<String, dynamic> encryptSensitiveFields(Map<String, dynamic> data) {
    final sensitiveFields = ['email', 'phone', 'address', 'payment_method'];
    final encryptedData = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (encryptedData.containsKey(field)) {
        encryptedData['${field}_encrypted'] = _encryptField(encryptedData[field]);
        encryptedData.remove(field);
      }
    }

    return encryptedData;
  }
}
```

#### Encryption in Transit

```dart
// lib/core/security/secure_transport.dart
class SecureTransportConfig {
  static const Duration certExpiryWarning = Duration(days: 30);
  static const String certProvider = 'aws-acm';

  // Certificate pinning
  static const Map<String, String> certificatePins = {
    'api.craftmarketplace.com': 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'stripe.com': 'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  };

  // HTTP client with security
  static http.Client createSecureClient() {
    return http.Client()
      ..timeout = Duration(seconds: 30)
      ..onBadCertificate = (certificate, host) {
        // Implement certificate pinning
        return _validateCertificate(certificate, host);
      };
  }
}
```

## 3. Content Protection Security

### 3.1 Media Pipeline Security

```dart
// lib/features/media/security/media_security.dart
class MediaSecurityService {
  // Signed URL generation for video streaming
  static String generateSignedUrl(String videoPath, String userId, Duration expiry) {
    final timestamp = DateTime.now().add(expiry).millisecondsSinceEpoch;
    final signature = _generateSignature(videoPath, userId, timestamp);

    return 'https://cdn.craftmarketplace.com/videos/$videoPath?' +
           'user_id=$userId&expires=$timestamp&signature=$signature';
  }

  // Video watermarking
  static Future<Uint8List> applyWatermark(
    Uint8List videoData,
    String userId,
    String sessionId,
  ) async {
    // Apply session-specific watermark
    final watermark = _generateWatermark(userId, sessionId);
    return await _overlayWatermark(videoData, watermark);
  }

  // DRM-style protection flags
  static Map<String, dynamic> getVideoProtectionConfig() {
    return {
      'prevent_capture': true,
      'disable_share': true,
      'no_download': true,
      'session_bound': true,
      'watermark_enabled': true,
      'signed_urls': true,
      'geo_restrictions': ['US', 'CA'], // MVP scope
    };
  }
}
```

### 3.2 Platform-Specific Security

```dart
// Android FLAG_SECURE configuration
// lib/features/media/security/android_security.dart
class AndroidSecurityConfig {
  static const Map<String, bool> secureFlags = {
    'FLAG_SECURE': true,        // Prevent screenshots
    'FLAG_KEEP_SCREEN_ON': false,
    'FLAG_HARDWARE_ACCELERATED': true,
  };

  // Screen capture detection
  static Future<bool> isScreenRecordingDetected() async {
    // Implement screen recording detection
    return await _detectScreenRecording();
  }
}

// iOS Security Configuration
// lib/features/media/security/ios_security.dart
class IOSSecurityConfig {
  static const Map<String, dynamic> secureConfig = {
    'preventScreenshots': true,
    'preventScreenRecording': true,
    'jailbreakDetection': true,
    'debuggerDetection': true,
  };

  // Capture detection
  static Future<void> setupCaptureDetection() async {
    // iOS-specific capture detection setup
    await _setupIOSCaptureDetection();
  }
}
```

## 4. API Security

### 4.1 API Rate Limiting

```dart
// lib/core/security/rate_limiting.dart
class RateLimitConfig {
  static const Map<String, RateLimit> endpoints = {
    '/auth/login': RateLimit(requests: 5, window: Duration(minutes: 15)),
    '/auth/register': RateLimit(requests: 3, window: Duration(hours: 1)),
    '/offers': RateLimit(requests: 10, window: Duration(minutes: 1)),
    '/bids': RateLimit(requests: 20, window: Duration(minutes: 5)),
    '/upload': RateLimit(requests: 5, window: Duration(minutes: 10)),
  };
}

class RateLimit {
  final int requests;
  final Duration window;

  const RateLimit({required this.requests, required this.window});
}
```

### 4.2 Input Validation

```dart
// lib/core/security/input_validation.dart
class InputValidator {
  static final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final phoneRegex = RegExp(r'^\+?1?\d{9,15}$');
  static final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  static ValidationResult validateInput(String input, ValidationType type) {
    switch (type) {
      case ValidationType.email:
        return _validateEmail(input);
      case ValidationType.phone:
        return _validatePhone(input);
      case ValidationType.username:
        return _validateUsername(input);
      case ValidationType.content:
        return _validateContent(input);
    }
  }

  static ValidationResult _validateContent(String content) {
    // Check for malicious content
    if (content.contains('<script>') || content.contains('javascript:')) {
      return ValidationResult(false, 'Invalid content detected');
    }

    // Length validation
    if (content.length > 10000) {
      return ValidationResult(false, 'Content too long');
    }

    return ValidationResult(true, 'Valid content');
  }
}
```

## 5. Security Monitoring & Logging

### 5.1 Security Event Logging

```dart
// lib/core/security/security_logging.dart
class SecurityLogger {
  static void logSecurityEvent(SecurityEvent event) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'event_type': event.type.toString(),
      'user_id': event.userId,
      'ip_address': event.ipAddress,
      'user_agent': event.userAgent,
      'severity': event.severity.toString(),
      'details': event.details,
    };

    // Send to security monitoring service
    _sendToSecurityMonitor(logEntry);

    // Log to structured logging
    logger.warning('Security event', logEntry);
  }
}

enum SecurityEventType {
  loginSuccess,
  loginFailure,
  unauthorizedAccess,
  suspiciousActivity,
  dataAccess,
  permissionChange,
}

class SecurityEvent {
  final SecurityEventType type;
  final String? userId;
  final String? ipAddress;
  final String? userAgent;
  final SecuritySeverity severity;
  final Map<String, dynamic> details;

  SecurityEvent({
    required this.type,
    this.userId,
    this.ipAddress,
    this.userAgent,
    required this.severity,
    required this.details,
  });
}
```

### 5.2 Intrusion Detection

```dart
// lib/core/security/intrusion_detection.dart
class IntrusionDetectionService {
  static final Map<String, List<DateTime>> failedLoginAttempts = {};
  static final Map<String, List<String>> suspiciousIPs = {};

  static bool detectSuspiciousActivity(String userId, String ipAddress) {
    // Check for multiple failed login attempts
    if (_hasMultipleFailedLogins(ipAddress)) {
      _lockoutIP(ipAddress);
      return true;
    }

    // Check for unusual access patterns
    if (_hasUnusualAccessPattern(userId, ipAddress)) {
      _flagSuspiciousActivity(userId, ipAddress);
      return true;
    }

    return false;
  }

  static void _lockoutIP(String ipAddress) {
    // Implement IP lockout mechanism
    SecurityLogger.logSecurityEvent(SecurityEvent(
      type: SecurityEventType.unauthorizedAccess,
      ipAddress: ipAddress,
      severity: SecuritySeverity.high,
      details: {'action': 'ip_lockout'},
    ));
  }
}
```

## 6. Compliance & Data Protection

### 6.1 GDPR Compliance

```dart
// lib/core/security/gdpr_compliance.dart
class GDPRService {
  // Data retention settings
  static const Map<String, Duration> retentionPeriods = {
    'user_data': Duration(days: 365 * 7), // 7 years
    'transaction_data': Duration(days: 365 * 10), // 10 years
    'analytics_data': Duration(days: 395), // 13 months
    'logs': Duration(days: 30), // 30 days
  };

  // Data export for DSAR
  static Future<Map<String, dynamic>> exportUserData(String userId) async {
    return {
      'profile': await _getUserProfile(userId),
      'transactions': await _getUserTransactions(userId),
      'activity_logs': await _getUserActivityLogs(userId),
      'consents': await _getUserConsents(userId),
      'export_date': DateTime.now().toIso8601String(),
    };
  }

  // Data deletion for right to be forgotten
  static Future<void> deleteUserData(String userId) async {
    await _anonymizeUserData(userId);
    await _deleteSensitiveData(userId);
    await _confirmDataDeletion(userId);
  }
}
```

### 6.2 PCI DSS Compliance (SAQ A)

```dart
// lib/features/payment/security/pci_compliance.dart
class PCIComplianceConfig {
  // Ensure no card data touches our servers
  static const bool neverStoreCardData = true;
  static const bool useStripeHostedCheckout = true;
  static const bool implement3DS = true;

  // Idempotency and security
  static Map<String, String> createSecureCheckoutSession() {
    return {
      'idempotency_key': _generateIdempotencyKey(),
      'success_url': 'https://app.craftmarketplace.com/payment/success',
      'cancel_url': 'https://app.craftmarketplace.com/payment/cancel',
      'payment_method_types': 'card',
      'mode': 'payment',
    };
  }

  static String _generateIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(1000000);
    return 'checkout_${timestamp}_$random';
  }
}
```

## 7. Security Testing Requirements

### 7.1 Security Test Suite

```dart
// test/security/security_test_suite.dart
void main() {
  group('Security Tests', () {
    test('Authentication tokens are properly signed', () async {
      final token = await AuthService.generateToken(testUser);
      expect(await TokenValidator.validate(token), isTrue);
    });

    test('Input validation blocks malicious content', () {
      final maliciousInput = '<script>alert("xss")</script>';
      final result = InputValidator.validateInput(maliciousInput, ValidationType.content);
      expect(result.isValid, isFalse);
    });

    test('Rate limiting prevents abuse', () async {
      for (int i = 0; i < 10; i++) {
        await AuthService.login('test@example.com', 'password');
      }
      // Should be rate limited
      expect(await AuthService.login('test@example.com', 'password'), throwsException);
    });

    test('Data encryption works correctly', () async {
      final plaintext = 'sensitive data';
      final encrypted = await EncryptionService.encrypt(plaintext, 'password');
      final decrypted = await EncryptionService.decrypt(encrypted, 'password');
      expect(decrypted, equals(plaintext));
    });
  });
}
```

### 7.2 Penetration Testing Checklist

```markdown
## Penetration Testing Requirements

### Authentication & Authorization
- [ ] Test for weak passwords
- [ ] Test JWT token manipulation
- [ ] Test privilege escalation
- [ ] Test session hijacking
- [ ] Test account lockout bypass

### API Security
- [ ] Test for SQL injection
- [ ] Test for XSS vulnerabilities
- [ ] Test for CSRF attacks
- [ ] Test rate limiting bypass
- [ ] Test API enumeration

### Data Protection
- [ ] Test data encryption at rest
- [ ] Test data encryption in transit
- [ ] Test data leakage through logs
- [ ] Test insecure data storage

### Infrastructure Security
- [ ] Test network security
- [ ] Test SSL/TLS configuration
- [ ] Test server hardening
- [ ] Test access controls

### Mobile Security
- [ ] Test local data storage
- [ ] Test certificate pinning
- [ ] Test jailbreak/root detection
- [ ] Test screen recording prevention
```

## 8. Security Deployment Checklist

### 8.1 Production Security Checklist

```markdown
## Pre-Deployment Security Checklist

### Infrastructure
- [ ] SSL certificates installed and valid
- [ ] Security groups configured correctly
- [ ] Database encryption enabled
- [ ] Backup encryption configured
- [ ] Monitoring and alerting configured

### Application
- [ ] Environment variables secured
- [ ] API keys stored in secret manager
- [ ] Debug mode disabled
- [ ] Error messages sanitized
- [ ] Security headers configured

### Dependencies
- [ ] All dependencies scanned for vulnerabilities
- [ ] Outdated packages updated
- [ ] Security patches applied
- [ ] License compliance verified

### Testing
- [ ] Security tests passing
- [ ] Penetration test completed
- [ ] Performance tests under load
- [ ] Failover procedures tested
```

This comprehensive security configuration ensures the Craft Video Marketplace meets all security NFRs from the PRD and provides a robust foundation for protecting user data and content.