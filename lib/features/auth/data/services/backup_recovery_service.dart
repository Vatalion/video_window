import 'package:flutter/material.dart';
import '../../domain/models/security_question_model.dart';
import '../../domain/models/recovery_token_model.dart';
import '../../domain/models/recovery_attempt_model.dart';
import 'password_reset_service.dart';

class BackupRecoveryService {
  final PasswordResetService _passwordResetService;
  final String _encryptionKey;

  BackupRecoveryService({
    required PasswordResetService passwordResetService,
    required String encryptionKey,
  }) : _passwordResetService = passwordResetService,
       _encryptionKey = encryptionKey;

  Future<List<SecurityQuestionModel>> getUserSecurityQuestions(
    String userId,
  ) async {
    // Mock implementation - retrieve user's security questions
    debugPrint('Getting security questions for user: $userId');
    return [];
  }

  Future<bool> validateSecurityAnswers({
    required String userId,
    required List<SecurityAnswerModel> answers,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Get stored questions
    final storedQuestions = await getUserSecurityQuestions(userId);

    // Validate each answer
    for (final answer in answers) {
      final question = storedQuestions.firstWhere(
        (q) => q.id == answer.questionId,
        orElse: () => throw Exception('Security question not found'),
      );

      if (!_verifySecurityAnswer(question, answer.answer)) {
        await _logRecoveryAttempt(
          userId: userId,
          type: RecoveryAttemptType.securityQuestion,
          wasSuccessful: false,
          failureReason: 'Incorrect security answer',
          ipAddress: ipAddress,
          userAgent: userAgent,
          wasSuspicious: true,
          suspicionReason: 'Incorrect security answer attempt',
        );
        return false;
      }
    }

    await _logRecoveryAttempt(
      userId: userId,
      type: RecoveryAttemptType.securityQuestion,
      wasSuccessful: true,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    return true;
  }

  Future<RecoveryTokenModel> createBackupEmailReset({
    required String userId,
    required String backupEmail,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Verify backup email belongs to user
    if (!await _verifyBackupEmailOwnership(userId, backupEmail)) {
      throw Exception('Backup email not associated with account');
    }

    // Create password reset token for backup email
    final token = await _passwordResetService.createEmailResetToken(
      userId: userId,
      email: backupEmail,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    // Update token type
    return RecoveryTokenModel(
      id: token.id,
      userId: token.userId,
      type: RecoveryTokenType.backupEmail,
      token: token.token,
      email: backupEmail,
      expiresAt: token.expiresAt,
      isUsed: token.isUsed,
      attemptsRemaining: token.attemptsRemaining,
      ipAddress: token.ipAddress,
      userAgent: token.userAgent,
      createdAt: token.createdAt,
    );
  }

  Future<RecoveryTokenModel> createBackupPhoneRecovery({
    required String userId,
    required String backupPhone,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Verify backup phone belongs to user
    if (!await _verifyBackupPhoneOwnership(userId, backupPhone)) {
      throw Exception('Backup phone not associated with account');
    }

    // Create recovery token for backup phone
    final token = RecoveryTokenModel(
      id: _generateId(),
      userId: userId,
      type: RecoveryTokenType.backupPhone,
      token: _generateSecureToken(),
      phoneNumber: backupPhone,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      isUsed: false,
      attemptsRemaining: 3,
      ipAddress: ipAddress,
      userAgent: userAgent,
      createdAt: DateTime.now(),
    );

    await _storeRecoveryToken(token);

    await _logRecoveryAttempt(
      userId: userId,
      type: RecoveryAttemptType.backupPhone,
      identifier: backupPhone,
      wasSuccessful: true,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    return token;
  }

  Future<bool> setupSecurityQuestions({
    required String userId,
    required List<SecurityQuestionModel> questions,
  }) async {
    try {
      for (final question in questions) {
        await _storeSecurityQuestion(question);
      }
      debugPrint('Security questions set up for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Failed to set up security questions: $e');
      return false;
    }
  }

  Future<bool> verifyBackupMethod({
    required String userId,
    required String identifier, // email or phone
    required RecoveryTokenType type,
    required String ipAddress,
    required String userAgent,
  }) async {
    bool isValid = false;

    switch (type) {
      case RecoveryTokenType.backupEmail:
        isValid = await _verifyBackupEmailOwnership(userId, identifier);
        break;
      case RecoveryTokenType.backupPhone:
        isValid = await _verifyBackupPhoneOwnership(userId, identifier);
        break;
      default:
        isValid = false;
    }

    await _logRecoveryAttempt(
      userId: userId,
      type: type == RecoveryTokenType.backupEmail
          ? RecoveryAttemptType.backupEmail
          : RecoveryAttemptType.backupPhone,
      identifier: identifier,
      wasSuccessful: isValid,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    return isValid;
  }

  bool _verifySecurityAnswer(
    SecurityQuestionModel question,
    String providedAnswer,
  ) {
    // Hash the provided answer and compare with stored hash
    final answerHash = _hashSecurityAnswer(providedAnswer);
    return answerHash == question.answerHash;
  }

  String _hashSecurityAnswer(String answer) {
    // In production, use a proper hashing algorithm
    return answer.hashCode.toString();
  }

  String _generateSecureToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.hashCode.toString();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<bool> _verifyBackupEmailOwnership(String userId, String email) async {
    // Mock implementation - verify email belongs to user
    debugPrint('Verifying backup email $email for user $userId');
    return true;
  }

  Future<bool> _verifyBackupPhoneOwnership(String userId, String phone) async {
    // Mock implementation - verify phone belongs to user
    debugPrint('Verifying backup phone $phone for user $userId');
    return true;
  }

  Future<void> _storeSecurityQuestion(SecurityQuestionModel question) async {
    // Mock implementation - store security question
    debugPrint('Storing security question for user: ${question.userId}');
  }

  Future<void> _storeRecoveryToken(RecoveryTokenModel token) async {
    // Mock implementation - store recovery token
    debugPrint('Storing backup recovery token for user: ${token.userId}');
  }

  Future<void> _logRecoveryAttempt({
    required String userId,
    required RecoveryAttemptType type,
    String? identifier,
    required bool wasSuccessful,
    String? failureReason,
    required String ipAddress,
    required String userAgent,
    String? deviceId,
    bool wasSuspicious = false,
    String? suspicionReason,
  }) async {
    final attempt = RecoveryAttemptModel(
      id: _generateId(),
      userId: userId,
      type: type,
      identifier: identifier,
      wasSuccessful: wasSuccessful,
      failureReason: failureReason,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      wasSuspicious: wasSuspicious,
      suspicionReason: suspicionReason,
      createdAt: DateTime.now(),
    );

    // Mock implementation
    debugPrint('Logging backup recovery attempt: ${attempt.toJson()}');
  }
}
