import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/recovery_models.dart';
import '../../domain/repositories/recovery_repository.dart';
import '../datasources/recovery_local_datasource.dart';
import '../datasources/recovery_remote_datasource.dart';

class RecoveryRepositoryImpl implements RecoveryRepository {
  final RecoveryRemoteDataSource remoteDataSource;
  final RecoveryLocalDataSource localDataSource;

  RecoveryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // Email-based recovery
  @override
  Future<RecoveryResult> requestEmailRecovery(String email) async {
    try {
      // Check if account is locked
      if (await isAccountLocked(email)) {
        final lockStatus = await getAccountLockStatus(email);
        final lockedUntil = await localDataSource.getAccountLockUntil(email);

        return RecoveryResult(
          success: false,
          error: 'Account is locked',
          errorType: RecoveryErrorType.accountLocked,
          isAccountLocked: true,
          lockStatus: lockStatus,
          lockedUntil: lockedUntil,
        );
      }

      // Check for suspicious activity
      final ipAddress = await _getCurrentIpAddress();
      if (await isSuspiciousActivity(email, ipAddress)) {
        await lockAccount(email, status: AccountLockStatus.lockedTemporary);
        return RecoveryResult(
          success: false,
          error: 'Suspicious activity detected. Account temporarily locked.',
          errorType: RecoveryErrorType.accountLocked,
          isAccountLocked: true,
          lockStatus: AccountLockStatus.lockedTemporary,
        );
      }

      // Generate secure token
      final token = _generateSecureToken();
      final tokenHash = _hashToken(token);
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      // Store recovery token
      await remoteDataSource.storeRecoveryToken(
        RecoveryToken(
          id: const Uuid().v4(),
          tokenHash: tokenHash,
          email: email,
          method: RecoveryMethod.email,
          expiresAt: expiresAt,
          isUsed: false,
          createdAt: DateTime.now(),
        ),
      );

      // Send recovery email
      await _sendRecoveryEmail(email, token, expiresAt);

      // Log recovery attempt
      await logRecoveryAttempt(
        RecoveryAttempt(
          id: const Uuid().v4(),
          email: email,
          method: RecoveryMethod.email,
          ipAddress: ipAddress,
          userAgent: await _getUserAgent(),
          wasSuccessful: true,
          attemptedAt: DateTime.now(),
        ),
      );

      return RecoveryResult(
        success: true,
        expiresAt: expiresAt,
        email: email,
      );
    } catch (e) {
      await logRecoveryAttempt(
        RecoveryAttempt(
          id: const Uuid().v4(),
          email: email,
          method: RecoveryMethod.email,
          ipAddress: await _getCurrentIpAddress(),
          userAgent: await _getUserAgent(),
          wasSuccessful: false,
          attemptedAt: DateTime.now(),
          failureReason: e.toString(),
        ),
      );

      return RecoveryResult(
        success: false,
        error: e.toString(),
        errorType: RecoveryErrorType.serverError,
      );
    }
  }

  // Phone-based recovery
  @override
  Future<RecoveryResult> requestPhoneRecovery(String phoneNumber) async {
    try {
      // Generate 6-digit verification code
      final verificationCode = _generateVerificationCode();
      final tokenHash = _hashToken(verificationCode);
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // Store recovery token
      await remoteDataSource.storeRecoveryToken(
        RecoveryToken(
          id: const Uuid().v4(),
          tokenHash: tokenHash,
          phoneNumber: phoneNumber,
          method: RecoveryMethod.phoneNumber,
          expiresAt: expiresAt,
          isUsed: false,
          createdAt: DateTime.now(),
        ),
      );

      // Send SMS (implementation depends on SMS service)
      await _sendRecoverySMS(phoneNumber, verificationCode);

      // Log recovery attempt
      await logRecoveryAttempt(
        RecoveryAttempt(
          id: const Uuid().v4(),
          email: '', // Phone-based recovery
          phoneNumber: phoneNumber,
          method: RecoveryMethod.phoneNumber,
          ipAddress: await _getCurrentIpAddress(),
          userAgent: await _getUserAgent(),
          wasSuccessful: true,
          attemptedAt: DateTime.now(),
        ),
      );

      return RecoveryResult(
        success: true,
        expiresAt: expiresAt,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      return RecoveryResult(
        success: false,
        error: e.toString(),
        errorType: RecoveryErrorType.serverError,
      );
    }
  }

  @override
  Future<bool> verifyRecoveryToken(String email, String token) async {
    try {
      final recoveryToken = await remoteDataSource.getRecoveryToken(email, token);

      if (recoveryToken == null) {
        return false;
      }

      // Check if token is expired or already used
      if (recoveryToken.isExpired || recoveryToken.isUsed) {
        return false;
      }

      // Verify token hash
      final tokenHash = _hashToken(token);
      return tokenHash == recoveryToken.tokenHash;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<RecoveryResult> resetPassword(
    String email,
    String newPassword,
    String token,
  ) async {
    try {
      // Verify token first
      final isValid = await verifyRecoveryToken(email, token);
      if (!isValid) {
        return RecoveryResult(
          success: false,
          error: 'Invalid or expired token',
          errorType: RecoveryErrorType.tokenNotFound,
        );
      }

      // Reset password (call to authentication service)
      await remoteDataSource.resetUserPassword(email, newPassword);

      // Mark token as used
      await remoteDataSource.markTokenAsUsed(email, token);

      // Send security notification
      await sendSecurityNotification(
        email,
        'Your password has been successfully reset. If this was not you, please contact support immediately.',
      );

      return RecoveryResult(
        success: true,
        email: email,
      );
    } catch (e) {
      return RecoveryResult(
        success: false,
        error: e.toString(),
        errorType: RecoveryErrorType.serverError,
      );
    }
  }

  @override
  Future<bool> verifySecurityQuestion(String questionId, String answer) async {
    try {
      final question = await remoteDataSource.getSecurityQuestion(questionId);
      if (question == null) return false;

      final answerHash = _hashToken(answer.toLowerCase().trim());
      return answerHash == question.answerHash;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<SecurityQuestion>> getSecurityQuestions() async {
    return await remoteDataSource.getSecurityQuestions();
  }

  @override
  Future<bool> setSecurityQuestion(String question, String answer) async {
    try {
      final answerHash = _hashToken(answer.toLowerCase().trim());
      final securityQuestion = SecurityQuestion(
        id: const Uuid().v4(),
        question: question,
        answerHash: answerHash,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await remoteDataSource.saveSecurityQuestion(securityQuestion);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<RecoveryResult> initiateBackupRecovery(RecoveryMethod method) async {
    try {
      // Implementation depends on user's configured backup methods
      final backupInfo = await remoteDataSource.getBackupRecoveryInfo(method);

      if (backupInfo == null) {
        return RecoveryResult(
          success: false,
          error: 'Backup method not configured',
          errorType: RecoveryErrorType.backupMethodNotAvailable,
        );
      }

      switch (method) {
        case RecoveryMethod.backupEmail:
          return await requestEmailRecovery(backupInfo.email);
        case RecoveryMethod.backupPhone:
          return await requestPhoneRecovery(backupInfo.phoneNumber);
        case RecoveryMethod.securityQuestion:
          return RecoveryResult(
            success: true,
            email: backupInfo.email,
          );
        default:
          return RecoveryResult(
            success: false,
            error: 'Unsupported backup method',
            errorType: RecoveryErrorType.backupMethodNotAvailable,
          );
      }
    } catch (e) {
      return RecoveryResult(
        success: false,
        error: e.toString(),
        errorType: RecoveryErrorType.serverError,
      );
    }
  }

  @override
  Future<RecoveryStatusInfo> getRecoveryStatus(String email) async {
    try {
      final availableMethods = await remoteDataSource.getAvailableRecoveryMethods(email);
      final lastAttempt = await remoteDataSource.getLastRecoveryAttempt(email);
      final failedAttempts = await remoteDataSource.getFailedRecoveryAttempts(email);

      return RecoveryStatusInfo(
        availableMethods: availableMethods,
        currentStatus: RecoveryStatus.pending,
        lastRecoveryAttempt: lastAttempt?.attemptedAt,
        failedAttempts: failedAttempts.length,
      );
    } catch (e) {
      return RecoveryStatusInfo(
        availableMethods: [],
        currentStatus: RecoveryStatus.failed,
      );
    }
  }

  @override
  Future<List<RecoveryAttempt>> getRecoveryAttempts(String email) async {
    return await remoteDataSource.getRecoveryAttempts(email);
  }

  @override
  Future<void> logRecoveryAttempt(RecoveryAttempt attempt) async {
    await remoteDataSource.logRecoveryAttempt(attempt);

    // Check for suspicious patterns
    if (await _isSuspiciousPattern(attempt.email)) {
      await lockAccount(attempt.email, status: AccountLockStatus.lockedTemporary);
    }
  }

  @override
  Future<bool> isAccountLocked(String email) async {
    final lockStatus = await getAccountLockStatus(email);
    return lockStatus != AccountLockStatus.unlocked;
  }

  @override
  Future<AccountLockStatus> getAccountLockStatus(String email) async {
    return await remoteDataSource.getAccountLockStatus(email);
  }

  @override
  Future<void> lockAccount(String email, {AccountLockStatus? status}) async {
    final lockStatus = status ?? AccountLockStatus.lockedTemporary;
    final lockedUntil = lockStatus == AccountLockStatus.lockedTemporary
        ? DateTime.now().add(const Duration(minutes: 15))
        : null;

    await remoteDataSource.lockAccount(email, lockStatus, lockedUntil);
    await localDataSource.saveAccountLockInfo(email, lockStatus, lockedUntil);
  }

  @override
  Future<void> unlockAccount(String email) async {
    await remoteDataSource.unlockAccount(email);
    await localDataSource.removeAccountLockInfo(email);
  }

  @override
  Future<bool> isSuspiciousActivity(String email, String ipAddress) async {
    // Check for rapid successive attempts
    final recentAttempts = await remoteDataSource.getRecentRecoveryAttempts(
      email,
      const Duration(minutes: 15),
    );

    if (recentAttempts.length >= 5) {
      return true;
    }

    // Check for multiple IP addresses
    final uniqueIPs = recentAttempts.map((a) => a.ipAddress).toSet().length;
    if (uniqueIPs >= 3) {
      return true;
    }

    return false;
  }

  @override
  Future<void> sendSecurityNotification(String email, String message) async {
    try {
      await remoteDataSource.sendSecurityNotification(email, message);
    } catch (e) {
      // Log error but don't fail the recovery process
      print('Failed to send security notification: $e');
    }
  }

  // Helper methods
  String _generateSecureToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String _generateVerificationCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _getCurrentIpAddress() async {
    // In a real app, this would get the actual IP address
    return '127.0.0.1';
  }

  Future<String> _getUserAgent() async {
    // In a real app, this would get the actual user agent
    return 'VideoWindow App/1.0';
  }

  Future<bool> _isSuspiciousPattern(String email) async {
    final attempts = await remoteDataSource.getRecentRecoveryAttempts(
      email,
      const Duration(hours: 1),
    );

    // Check for too many failed attempts
    final failedAttempts = attempts.where((a) => !a.wasSuccessful).length;
    return failedAttempts >= 5;
  }

  Future<void> _sendRecoveryEmail(String email, String token, DateTime expiresAt) async {
    // Configure SMTP settings (in production, these would be configurable)
    final smtpServer = SmtpServer(
      'smtp.example.com',
      username: 'noreply@videowindow.com',
      password: 'your-password',
      port: 587,
      ssl: false,
      allowInsecure: true,
    );

    final message = Message()
      ..from = Address('noreply@videowindow.com', 'VideoWindow Support')
      ..recipients.add(email)
      ..subject = 'Password Reset Request'
      ..html = '''
        <h2>Password Reset Request</h2>
        <p>You have requested to reset your password for your VideoWindow account.</p>
        <p>Click the link below to reset your password:</p>
        <p><a href="https://app.videowindow.com/reset-password?token=$token&email=${Uri.encodeComponent(email)}">Reset Password</a></p>
        <p>This link will expire on ${expiresAt.toLocal()}.</p>
        <p>If you did not request this reset, please ignore this email or contact support.</p>
        <p>Best regards,<br>VideoWindow Team</p>
      ''';

    try {
      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Failed to send recovery email: $e');
    }
  }

  Future<void> _sendRecoverySMS(String phoneNumber, String code) async {
    // SMS implementation would go here
    // This would integrate with an SMS service like Twilio, AWS SNS, etc.
    print('SMS sent to $phoneNumber with code: $code');
  }
}