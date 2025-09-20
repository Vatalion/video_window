import 'dart:async';
import 'dart:math';
import 'package:meta/meta.dart';

class EmailService {
  static const Duration _linkExpiry = Duration(hours: 24);
  static const int _maxEmailsPerHour = 5;
  static const int _maxVerificationAttempts = 10;
  static const String _baseUrl = 'https://videowindow.app/verify';

  final Map<String, _EmailRequestData> _activeRequests = {};
  final Map<String, int> _hourlyEmailCounts = {};
  final Map<String, int> _verificationAttemptCounts = {};

  Future<bool> sendVerificationEmail({
    required String email,
    required String userId,
    required String token,
  }) async {
    if (!_canSendEmail(email)) {
      throw EmailRateLimitExceededException(
        'Email rate limit exceeded. Please try again later.',
      );
    }

    final verificationLink =
        '$_baseUrl?token=$token&email=$email&user_id=$userId';
    final expiryTime = DateTime.now().add(_linkExpiry);

    _activeRequests[email] = _EmailRequestData(
      token: token,
      verificationLink: verificationLink,
      expiryTime: expiryTime,
      userId: userId,
      attemptCount: 0,
    );

    _incrementEmailCount(email);

    try {
      final success = await _sendEmailToProvider(
        toEmail: email,
        subject: 'Verify your email address',
        htmlBody: _buildVerificationEmailHtml(verificationLink, expiryTime),
        textBody: _buildVerificationEmailText(verificationLink, expiryTime),
      );

      if (!success) {
        _activeRequests.remove(email);
        return false;
      }

      return true;
    } catch (e) {
      _activeRequests.remove(email);
      _decrementEmailCount(email);
      rethrow;
    }
  }

  Future<bool> verifyEmailToken({
    required String email,
    required String token,
    required String userId,
  }) async {
    final requestData = _activeRequests[email];
    if (requestData == null) {
      throw EmailTokenExpiredException(
        'No active email verification request found.',
      );
    }

    if (requestData.userId != userId) {
      throw EmailTokenMismatchException('User ID mismatch.');
    }

    if (DateTime.now().isAfter(requestData.expiryTime)) {
      _activeRequests.remove(email);
      throw EmailTokenExpiredException('Email verification link has expired.');
    }

    if (!_canAttemptVerification(email)) {
      throw EmailVerificationLimitExceededException(
        'Too many verification attempts. Please request a new verification email.',
      );
    }

    _incrementVerificationAttemptCount(email);

    if (requestData.token == token) {
      _activeRequests.remove(email);
      _verificationAttemptCounts.remove(email);
      return true;
    } else {
      throw EmailTokenInvalidException('Invalid verification token.');
    }
  }

  Future<bool> resendVerificationEmail({
    required String email,
    required String userId,
  }) async {
    final requestData = _activeRequests[email];
    if (requestData != null) {
      _activeRequests.remove(email);
      _decrementEmailCount(email);
    }

    final newToken = _generateEmailToken();
    return sendVerificationEmail(email: email, userId: userId, token: newToken);
  }

  String _generateEmailToken() {
    final random = Random.secure();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final token = StringBuffer();

    for (int i = 0; i < 32; i++) {
      token.write(chars[random.nextInt(chars.length)]);
    }

    return token.toString();
  }

  String _buildVerificationEmailHtml(
    String verificationLink,
    DateTime expiryTime,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .button {
            background-color: #4CAF50;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 4px;
            display: inline-block;
        }
        .footer { font-size: 12px; color: #666; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Verify Your Email Address</h1>
        </div>
        <div class="content">
            <p>Thank you for registering with Video Window! Please verify your email address to complete your registration.</p>
            <p><a href="$verificationLink" class="button">Verify Email Address</a></p>
            <p>Or copy and paste this link into your browser:</p>
            <p><small>$verificationLink</small></p>
            <p>This link will expire on ${expiryTime.toLocal()}.</p>
            <p>If you didn't create an account with Video Window, please ignore this email.</p>
        </div>
        <div class="footer">
            <p>&copy; 2025 Video Window. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  String _buildVerificationEmailText(
    String verificationLink,
    DateTime expiryTime,
  ) {
    return '''
Verify Your Email Address

Thank you for registering with Video Window! Please verify your email address to complete your registration.

Click the link below to verify your email:
$verificationLink

Or copy and paste this link into your browser:
$verificationLink

This link will expire on ${expiryTime.toLocal()}.

If you didn't create an account with Video Window, please ignore this email.

© 2025 Video Window. All rights reserved.
    ''';
  }

  bool _canSendEmail(String email) {
    final count = _hourlyEmailCounts[email] ?? 0;
    return count < _maxEmailsPerHour;
  }

  bool _canAttemptVerification(String email) {
    final count = _verificationAttemptCounts[email] ?? 0;
    return count < _maxVerificationAttempts;
  }

  void _incrementEmailCount(String email) {
    _hourlyEmailCounts[email] = (_hourlyEmailCounts[email] ?? 0) + 1;

    Timer(Duration(hours: 1), () {
      _hourlyEmailCounts[email] = (_hourlyEmailCounts[email] ?? 1) - 1;
      if (_hourlyEmailCounts[email]! <= 0) {
        _hourlyEmailCounts.remove(email);
      }
    });
  }

  void _decrementEmailCount(String email) {
    if (_hourlyEmailCounts.containsKey(email)) {
      _hourlyEmailCounts[email] = (_hourlyEmailCounts[email] ?? 1) - 1;
      if (_hourlyEmailCounts[email]! <= 0) {
        _hourlyEmailCounts.remove(email);
      }
    }
  }

  void _incrementVerificationAttemptCount(String email) {
    _verificationAttemptCounts[email] =
        (_verificationAttemptCounts[email] ?? 0) + 1;

    Timer(Duration(minutes: 15), () {
      _verificationAttemptCounts[email] =
          (_verificationAttemptCounts[email] ?? 1) - 1;
      if (_verificationAttemptCounts[email]! <= 0) {
        _verificationAttemptCounts.remove(email);
      }
    });
  }

  Future<bool> _sendEmailToProvider({
    required String toEmail,
    required String subject,
    required String htmlBody,
    required String textBody,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  void clearExpiredRequests() {
    final now = DateTime.now();
    _activeRequests.removeWhere((email, data) {
      return now.isAfter(data.expiryTime);
    });
  }

  int getRemainingEmailAttempts(String email) {
    return max(0, _maxEmailsPerHour - (_hourlyEmailCounts[email] ?? 0));
  }

  int getRemainingVerificationAttempts(String email) {
    return max(
      0,
      _maxVerificationAttempts - (_verificationAttemptCounts[email] ?? 0),
    );
  }

  DateTime? getTokenExpiryTime(String email) {
    return _activeRequests[email]?.expiryTime;
  }

  void clearRequestData(String email) {
    _activeRequests.remove(email);
    _hourlyEmailCounts.remove(email);
    _verificationAttemptCounts.remove(email);
  }

  Future<bool> sendWelcomeEmail({
    required String email,
    required String displayName,
  }) async {
    if (!_canSendEmail(email)) {
      throw EmailRateLimitExceededException(
        'Email rate limit exceeded. Please try again later.',
      );
    }

    _incrementEmailCount(email);

    try {
      return await _sendEmailToProvider(
        toEmail: email,
        subject: 'Welcome to Video Window!',
        htmlBody: _buildWelcomeEmailHtml(displayName),
        textBody: _buildWelcomeEmailText(displayName),
      );
    } catch (e) {
      _decrementEmailCount(email);
      rethrow;
    }
  }

  String _buildWelcomeEmailHtml(String displayName) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .footer { font-size: 12px; color: #666; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to Video Window!</h1>
        </div>
        <div class="content">
            <p>Hi $displayName,</p>
            <p>Welcome to Video Window! We're excited to have you as part of our community.</p>
            <p>Your account has been successfully created and verified. You can now access all the features of our platform.</p>
            <p>Here's what you can do next:</p>
            <ul>
                <li>Complete your profile</li>
                <li>Explore our features</li>
                <li>Connect with other users</li>
            </ul>
            <p>If you have any questions, don't hesitate to reach out to our support team.</p>
            <p>Happy video streaming!</p>
        </div>
        <div class="footer">
            <p>&copy; 2025 Video Window. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  String _buildWelcomeEmailText(String displayName) {
    return '''
Welcome to Video Window!

Hi $displayName,

Welcome to Video Window! We're excited to have you as part of our community.

Your account has been successfully created and verified. You can now access all the features of our platform.

Here's what you can do next:
• Complete your profile
• Explore our features
• Connect with other users

If you have any questions, don't hesitate to reach out to our support team.

Happy video streaming!

© 2025 Video Window. All rights reserved.
    ''';
  }
}

class _EmailRequestData {
  final String token;
  final String verificationLink;
  final DateTime expiryTime;
  final String userId;
  final int attemptCount;

  _EmailRequestData({
    required this.token,
    required this.verificationLink,
    required this.expiryTime,
    required this.userId,
    required this.attemptCount,
  });
}

class EmailServiceException implements Exception {
  final String message;

  EmailServiceException(this.message);

  @override
  String toString() => 'EmailServiceException: $message';
}

class EmailRateLimitExceededException extends EmailServiceException {
  EmailRateLimitExceededException(String message) : super(message);
}

class EmailTokenExpiredException extends EmailServiceException {
  EmailTokenExpiredException(String message) : super(message);
}

class EmailTokenInvalidException extends EmailServiceException {
  EmailTokenInvalidException(String message) : super(message);
}

class EmailTokenMismatchException extends EmailServiceException {
  EmailTokenMismatchException(String message) : super(message);
}

class EmailVerificationLimitExceededException extends EmailServiceException {
  EmailVerificationLimitExceededException(String message) : super(message);
}
