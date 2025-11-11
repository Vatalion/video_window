import 'package:serverpod/serverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Email service for sending transactional emails via SendGrid
/// Implements AC2: Recovery emails with device + location metadata
class EmailService {
  final Session session;
  String? _sendGridApiKey;

  EmailService(this.session);

  /// Initialize SendGrid API key from config
  Future<void> _initSendGrid() async {
    if (_sendGridApiKey != null) return;

    try {
      // Get SendGrid API key from environment or config
      // TODO: Load from Serverpod config when environment variables are set up
      _sendGridApiKey = _getSendGridApiKeyFromEnv();

      if (_sendGridApiKey == null || _sendGridApiKey!.isEmpty) {
        session.log(
          'SendGrid API key not configured - emails will be logged only',
          level: LogLevel.warning,
        );
      }
    } catch (e) {
      session.log(
        'Failed to initialize SendGrid: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Get SendGrid API key from environment
  String? _getSendGridApiKeyFromEnv() {
    // TODO: Integrate with Serverpod config system
    // For now, return null to use dev mode (logging only)
    return null;
  }

  /// Send account recovery email
  /// AC2: Includes device + location metadata and "Not You?" revocation link
  Future<bool> sendRecoveryEmail({
    required String to,
    required String token,
    required String deviceInfo,
    required String ipAddress,
    String? userAgent,
    String? location,
  }) async {
    try {
      await _initSendGrid();

      final subject = '🔐 Account Recovery - Video Window';
      final htmlContent = _buildRecoveryEmailHtml(
        token: token,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        userAgent: userAgent,
        location: location,
      );
      final textContent = _buildRecoveryEmailText(
        token: token,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        userAgent: userAgent,
        location: location,
      );

      // If SendGrid is not configured, log the email in development mode
      if (_sendGridApiKey == null || _sendGridApiKey!.isEmpty) {
        session.log(
          '''
DEV MODE: Recovery email would be sent to: $to

Subject: $subject

$textContent

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HTML Preview:
$htmlContent
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SECURITY NOTE: In production, this will be sent via SendGrid
''',
          level: LogLevel.info,
        );
        return true; // Simulate success in dev mode
      }

      // Send via SendGrid API v3
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer $_sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {'email': to}
              ],
              'subject': subject,
            }
          ],
          'from': {
            'email': 'noreply@videowindow.com',
            'name': 'Video Window Security'
          },
          'content': [
            {
              'type': 'text/plain',
              'value': textContent,
            },
            {
              'type': 'text/html',
              'value': htmlContent,
            }
          ],
        }),
      );

      if (response.statusCode == 202) {
        session.log(
          'Recovery email sent successfully to: $to',
          level: LogLevel.info,
        );
        return true;
      } else {
        session.log(
          'Failed to send recovery email: ${response.statusCode} ${response.body}',
          level: LogLevel.error,
        );
        return false;
      }
    } catch (e, stackTrace) {
      session.log(
        'Error sending recovery email: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Build recovery email HTML content
  /// AC2: Includes device + location metadata and "Not You?" revocation link
  String _buildRecoveryEmailHtml({
    required String token,
    required String deviceInfo,
    required String ipAddress,
    String? userAgent,
    String? location,
  }) {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: 15));
    final formattedTime = _formatDateTime(now);
    final formattedExpiry = _formatDateTime(expiresAt);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none; }
    .token-box { background: #f5f7fa; border: 2px solid #667eea; border-radius: 8px; padding: 20px; margin: 20px 0; text-align: center; }
    .token { font-size: 24px; font-weight: bold; letter-spacing: 2px; color: #667eea; font-family: monospace; }
    .metadata { background: #fff9e6; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
    .metadata-title { font-weight: bold; color: #f57c00; margin-bottom: 10px; }
    .metadata-item { margin: 5px 0; font-size: 14px; }
    .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 10px 5px; }
    .button-danger { background: #dc3545; }
    .warning { background: #fff3cd; border: 1px solid #ffc107; border-radius: 6px; padding: 15px; margin: 20px 0; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔐 Account Recovery</h1>
      <p>Video Window Security</p>
    </div>
    
    <div class="content">
      <p>Hello,</p>
      
      <p>We received a request to recover your Video Window account. Use the token below to complete your account recovery:</p>
      
      <div class="token-box">
        <div style="color: #666; font-size: 14px; margin-bottom: 10px;">Your Recovery Token</div>
        <div class="token">$token</div>
        <div style="color: #666; font-size: 12px; margin-top: 10px;">Expires in 15 minutes</div>
      </div>
      
      <div style="text-align: center; margin: 20px 0;">
        <a href="https://app.videowindow.com/auth/recovery?token=$token" class="button">
          Recover Account
        </a>
      </div>
      
      <div class="metadata">
        <div class="metadata-title">⚠️ Security Information</div>
        <div class="metadata-item"><strong>Time:</strong> $formattedTime</div>
        <div class="metadata-item"><strong>Device:</strong> $deviceInfo</div>
        <div class="metadata-item"><strong>IP Address:</strong> $ipAddress</div>
        ${userAgent != null ? '<div class="metadata-item"><strong>Browser:</strong> $userAgent</div>' : ''}
        ${location != null ? '<div class="metadata-item"><strong>Location:</strong> $location</div>' : ''}
        <div class="metadata-item"><strong>Expires:</strong> $formattedExpiry</div>
      </div>
      
      <div class="warning">
        <strong>⚠️ Important:</strong>
        <ul style="margin: 10px 0; padding-left: 20px;">
          <li>This token expires in <strong>15 minutes</strong></li>
          <li>The token can only be used <strong>once</strong></li>
          <li>After 3 failed attempts, your account will be locked for 30 minutes</li>
        </ul>
      </div>
      
      <div style="text-align: center; margin: 30px 0;">
        <p style="color: #dc3545; font-weight: bold;">Not you?</p>
        <p>If you didn't request this recovery, someone may be trying to access your account.</p>
        <a href="https://app.videowindow.com/auth/recovery/revoke?token=$token" class="button button-danger">
          🚫 Cancel Recovery Request
        </a>
        <p style="font-size: 12px; color: #666; margin-top: 10px;">
          This will immediately revoke the recovery token and alert you.
        </p>
      </div>
      
      <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 30px 0;">
      
      <div style="font-size: 14px; color: #666;">
        <p><strong>Security Tips:</strong></p>
        <ul style="padding-left: 20px;">
          <li>Never share your recovery token with anyone</li>
          <li>Video Window will never ask for your token via email or phone</li>
          <li>If you suspect unauthorized access, revoke this token immediately</li>
        </ul>
      </div>
    </div>
    
    <div class="footer">
      <p>Video Window - Craft Video Marketplace</p>
      <p>This is an automated security message. Please do not reply to this email.</p>
      <p>If you continue to have issues, contact support at support@videowindow.com</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build recovery email plain text content
  String _buildRecoveryEmailText({
    required String token,
    required String deviceInfo,
    required String ipAddress,
    String? userAgent,
    String? location,
  }) {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: 15));
    final formattedTime = _formatDateTime(now);
    final formattedExpiry = _formatDateTime(expiresAt);

    return '''
🔐 ACCOUNT RECOVERY - VIDEO WINDOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hello,

We received a request to recover your Video Window account. Use the token below to complete your account recovery:

YOUR RECOVERY TOKEN:
$token

Recovery Link:
https://app.videowindow.com/auth/recovery?token=$token

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ SECURITY INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Time: $formattedTime
Device: $deviceInfo
IP Address: $ipAddress
${userAgent != null ? 'Browser: $userAgent\n' : ''}${location != null ? 'Location: $location\n' : ''}Expires: $formattedExpiry

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ IMPORTANT NOTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• This token expires in 15 minutes
• The token can only be used once
• After 3 failed attempts, your account will be locked for 30 minutes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚫 NOT YOU?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If you didn't request this recovery, someone may be trying to access your account.

Cancel Recovery Request:
https://app.videowindow.com/auth/recovery/revoke?token=$token

This will immediately revoke the recovery token and alert you.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SECURITY TIPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Never share your recovery token with anyone
• Video Window will never ask for your token via email or phone
• If you suspect unauthorized access, revoke this token immediately

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Video Window - Craft Video Marketplace
This is an automated security message. Please do not reply to this email.

If you continue to have issues, contact support at support@videowindow.com
''';
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)} UTC';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
