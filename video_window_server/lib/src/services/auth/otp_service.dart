import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import '../../generated/auth/otp.dart';

/// Secure OTP generation and validation service
/// Implements SEC-001 requirements with cryptographic security
class OtpService {
  static const int _codeLength = 6;
  static const Duration _validityPeriod = Duration(minutes: 5);
  static const int _maxAttempts = 5;

  final Session session;

  OtpService(this.session);

  /// Generate a cryptographically secure 6-digit OTP
  /// Uses Random.secure() as per SEC-001 requirements
  String generateSecureOTP() {
    final random = Random.secure();
    final code = List.generate(_codeLength, (_) => random.nextInt(10)).join();
    session.log('OTP generated', level: LogLevel.debug);
    return code;
  }

  /// Generate user-specific salt for OTP hashing
  /// Each user gets unique salt to prevent rainbow table attacks
  Future<String> _generateUserSpecificSalt(String identifier) async {
    final random = Random.secure();
    final saltBytes =
        List.generate(32, (_) => random.nextInt(256)); // 32 bytes = 256 bits
    final salt = base64Encode(saltBytes);

    session.log(
      'Generated salt for identifier',
      level: LogLevel.debug,
    );
    return salt;
  }

  /// Hash OTP with SHA-256 and user-specific salt
  /// SECURITY CRITICAL: Never store plaintext OTPs
  String hashOTP(String otp, String salt) {
    final bytes = utf8.encode(otp + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create and store a new OTP for the given identifier
  /// Returns the plaintext OTP (to be sent via email/SMS)
  /// Stores only the hashed version in database
  Future<String> createOTP(String identifier) async {
    try {
      // Generate cryptographically secure OTP
      final otp = generateSecureOTP();

      // Generate user-specific salt
      final salt = await _generateUserSpecificSalt(identifier);

      // Hash the OTP
      final otpHash = hashOTP(otp, salt);

      // Calculate expiry time (5 minutes from now)
      final expiresAt = DateTime.now().add(_validityPeriod);

      // Invalidate any existing OTPs for this identifier
      await _invalidateExistingOTPs(identifier);

      // Store OTP record with hash only (never plaintext)
      final otpRecord = Otp(
        identifier: identifier.toLowerCase().trim(),
        otpHash: otpHash,
        salt: salt,
        attempts: 0,
        used: false,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );

      await Otp.db.insertRow(session, otpRecord);

      session.log(
        'OTP created for identifier (hash stored)',
        level: LogLevel.info,
      );

      // Return plaintext OTP for sending (not stored anywhere)
      return otp;
    } catch (e) {
      session.log(
        'Failed to create OTP: $e',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Verify an OTP for the given identifier
  /// Implements one-time use enforcement and attempt tracking
  Future<OtpVerificationResult> verifyOTP(
    String identifier,
    String code,
  ) async {
    try {
      final normalizedIdentifier = identifier.toLowerCase().trim();

      // Find the most recent OTP for this identifier
      final otpRecords = await Otp.db.find(
        session,
        where: (t) =>
            t.identifier.equals(normalizedIdentifier) & t.used.equals(false),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 1,
      );

      if (otpRecords.isEmpty) {
        session.log(
          'OTP verification failed: No active OTP found',
          level: LogLevel.warning,
        );
        return OtpVerificationResult.notFound();
      }

      final otpRecord = otpRecords.first;

      // Check if OTP has expired
      if (DateTime.now().isAfter(otpRecord.expiresAt)) {
        session.log(
          'OTP verification failed: Expired',
          level: LogLevel.warning,
        );
        // Mark as used to prevent further attempts
        await _markOTPAsUsed(otpRecord.id!);
        return OtpVerificationResult.expired();
      }

      // Check if max attempts exceeded
      if (otpRecord.attempts >= _maxAttempts) {
        session.log(
          'OTP verification failed: Max attempts exceeded',
          level: LogLevel.warning,
        );
        await _markOTPAsUsed(otpRecord.id!);
        return OtpVerificationResult.maxAttemptsExceeded();
      }

      // Verify the OTP hash
      final providedHash = hashOTP(code, otpRecord.salt);
      final isValid = providedHash == otpRecord.otpHash;

      if (isValid) {
        // SUCCESS: Mark OTP as used immediately (one-time use enforcement)
        await _markOTPAsUsed(otpRecord.id!);
        session.log(
          'OTP verified successfully',
          level: LogLevel.info,
        );
        return OtpVerificationResult.success();
      } else {
        // FAILURE: Increment attempt counter
        await _incrementAttempts(otpRecord.id!);
        session.log(
          'OTP verification failed: Invalid code (attempt ${otpRecord.attempts + 1}/$_maxAttempts)',
          level: LogLevel.warning,
        );
        return OtpVerificationResult.invalid(otpRecord.attempts + 1);
      }
    } catch (e) {
      session.log(
        'OTP verification error: $e',
        level: LogLevel.error,
        exception: e,
      );
      return OtpVerificationResult.error();
    }
  }

  /// Invalidate all existing OTPs for an identifier
  /// Called before creating a new OTP to prevent multiple active codes
  Future<void> _invalidateExistingOTPs(String identifier) async {
    try {
      final normalizedIdentifier = identifier.toLowerCase().trim();

      // Find all unused OTPs for this identifier
      final existingOTPs = await Otp.db.find(
        session,
        where: (t) =>
            t.identifier.equals(normalizedIdentifier) & t.used.equals(false),
      );

      // Mark all as used
      for (final otp in existingOTPs) {
        await _markOTPAsUsed(otp.id!);
      }

      if (existingOTPs.isNotEmpty) {
        session.log(
          'Invalidated ${existingOTPs.length} existing OTP(s)',
          level: LogLevel.debug,
        );
      }
    } catch (e) {
      session.log(
        'Failed to invalidate existing OTPs: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Mark an OTP as used (one-time use enforcement)
  Future<void> _markOTPAsUsed(int otpId) async {
    try {
      final otp = await Otp.db.findById(session, otpId);
      if (otp != null) {
        otp.used = true;
        otp.usedAt = DateTime.now();
        await Otp.db.updateRow(session, otp);
      }
    } catch (e) {
      session.log(
        'Failed to mark OTP as used: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Increment attempt counter for failed verification
  Future<void> _incrementAttempts(int otpId) async {
    try {
      final otp = await Otp.db.findById(session, otpId);
      if (otp != null) {
        otp.attempts++;
        await Otp.db.updateRow(session, otp);
      }
    } catch (e) {
      session.log(
        'Failed to increment attempts: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Clean up expired OTPs (maintenance task)
  /// Should be called periodically to prevent database bloat
  Future<void> cleanupExpiredOTPs() async {
    try {
      final now = DateTime.now();
      final expiredOTPs = await Otp.db.find(
        session,
        where: (t) => t.expiresAt < now,
      );

      for (final otp in expiredOTPs) {
        await Otp.db.deleteRow(session, otp);
      }

      if (expiredOTPs.isNotEmpty) {
        session.log(
          'Cleaned up ${expiredOTPs.length} expired OTP(s)',
          level: LogLevel.info,
        );
      }
    } catch (e) {
      session.log(
        'Failed to cleanup expired OTPs: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }
}

/// Result of OTP verification with detailed status
class OtpVerificationResult {
  final bool success;
  final String message;
  final int? attempts;

  OtpVerificationResult._({
    required this.success,
    required this.message,
    this.attempts,
  });

  factory OtpVerificationResult.success() {
    return OtpVerificationResult._(
      success: true,
      message: 'OTP verified successfully',
    );
  }

  factory OtpVerificationResult.invalid(int attempts) {
    return OtpVerificationResult._(
      success: false,
      message: 'Invalid OTP code',
      attempts: attempts,
    );
  }

  factory OtpVerificationResult.expired() {
    return OtpVerificationResult._(
      success: false,
      message: 'OTP has expired',
    );
  }

  factory OtpVerificationResult.notFound() {
    return OtpVerificationResult._(
      success: false,
      message: 'No active OTP found',
    );
  }

  factory OtpVerificationResult.maxAttemptsExceeded() {
    return OtpVerificationResult._(
      success: false,
      message: 'Maximum verification attempts exceeded',
    );
  }

  factory OtpVerificationResult.error() {
    return OtpVerificationResult._(
      success: false,
      message: 'Internal error during verification',
    );
  }
}
