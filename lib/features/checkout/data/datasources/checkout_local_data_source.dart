import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_security_model.dart';
import '../../../core/error/failure.dart';

abstract class CheckoutLocalDataSource {
  // Session Storage
  Future<bool> saveSession(CheckoutSessionModel session);
  Future<CheckoutSessionModel?> getSession(String sessionId);
  Future<bool> removeSession(String sessionId);
  Future<List<CheckoutSessionModel>> getAllSessions();
  Future<bool> clearAllSessions();

  // Security Context Storage
  Future<bool> saveSecurityContext(SecurityContextModel context);
  Future<SecurityContextModel?> getSecurityContext(String sessionId);
  Future<bool> removeSecurityContext(String sessionId);

  // Cached Data
  Future<bool> cacheOrderSummary(String sessionId, Map<String, dynamic> summary);
  Future<Map<String, dynamic>?> getCachedOrderSummary(String sessionId);
  Future<bool> clearCachedOrderSummary(String sessionId);

  // Device Fingerprint
  Future<String> getDeviceFingerprint();
  Future<bool> saveDeviceFingerprint(String fingerprint);

  // Session Tokens
  Future<bool> saveSessionToken(String sessionId, String token);
  Future<String?> getSessionToken(String sessionId);
  Future<bool> removeSessionToken(String sessionId);
}

class CheckoutLocalDataSourceImpl implements CheckoutLocalDataSource {
  final SharedPreferences sharedPreferences;
  final Encrypter encrypter;

  static const String _sessionPrefix = 'checkout_session_';
  static const String _securityPrefix = 'checkout_security_';
  static const String _orderSummaryPrefix = 'checkout_summary_';
  static const String _tokenPrefix = 'checkout_token_';
  static const String _deviceFingerprintKey = 'checkout_device_fingerprint';

  CheckoutLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.encrypter,
  });

  @override
  Future<bool> saveSession(CheckoutSessionModel session) async {
    try {
      final sessionJson = json.encode(session.toJson());
      final encryptedData = encrypter.encrypt(sessionJson);

      return await sharedPreferences.setString(
        '$_sessionPrefix${session.sessionId}',
        encryptedData.base64,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<CheckoutSessionModel?> getSession(String sessionId) async {
    try {
      final encryptedData = sharedPreferences.getString('$_sessionPrefix$sessionId');
      if (encryptedData == null) return null;

      final decryptedData = encrypter.decrypt64(encryptedData);
      final sessionJson = json.decode(decryptedData) as Map<String, dynamic>;

      return CheckoutSessionModel.fromJson(sessionJson);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> removeSession(String sessionId) async {
    try {
      await sharedPreferences.remove('$_sessionPrefix$sessionId');
      await removeSecurityContext(sessionId);
      await removeSessionToken(sessionId);
      await clearCachedOrderSummary(sessionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<CheckoutSessionModel>> getAllSessions() async {
    try {
      final sessions = <CheckoutSessionModel>[];
      final keys = sharedPreferences.getKeys();

      for (final key in keys) {
        if (key.startsWith(_sessionPrefix)) {
          final sessionId = key.replaceFirst(_sessionPrefix, '');
          final session = await getSession(sessionId);
          if (session != null) {
            sessions.add(session);
          }
        }
      }

      // Filter out expired sessions
      final validSessions = sessions.where((session) => session.isValid).toList();

      // Clean up expired sessions
      for (final session in sessions) {
        if (!session.isValid) {
          await removeSession(session.sessionId);
        }
      }

      return validSessions;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> clearAllSessions() async {
    try {
      final keys = sharedPreferences.getKeys();
      for (final key in keys) {
        if (key.startsWith(_sessionPrefix) ||
            key.startsWith(_securityPrefix) ||
            key.startsWith(_orderSummaryPrefix) ||
            key.startsWith(_tokenPrefix)) {
          await sharedPreferences.remove(key);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> saveSecurityContext(SecurityContextModel context) async {
    try {
      final contextJson = json.encode(context.toJson());
      final encryptedData = encrypter.encrypt(contextJson);

      return await sharedPreferences.setString(
        '$_securityPrefix${context.sessionId}',
        encryptedData.base64,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SecurityContextModel?> getSecurityContext(String sessionId) async {
    try {
      final encryptedData = sharedPreferences.getString('$_securityPrefix$sessionId');
      if (encryptedData == null) return null;

      final decryptedData = encrypter.decrypt64(encryptedData);
      final contextJson = json.decode(decryptedData) as Map<String, dynamic>;

      return SecurityContextModel.fromJson(contextJson);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> removeSecurityContext(String sessionId) async {
    try {
      return await sharedPreferences.remove('$_securityPrefix$sessionId');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> cacheOrderSummary(String sessionId, Map<String, dynamic> summary) async {
    try {
      final summaryJson = json.encode(summary);
      final encryptedData = encrypter.encrypt(summaryJson);

      return await sharedPreferences.setString(
        '$_orderSummaryPrefix$sessionId',
        encryptedData.base64,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedOrderSummary(String sessionId) async {
    try {
      final encryptedData = sharedPreferences.getString('$_orderSummaryPrefix$sessionId');
      if (encryptedData == null) return null;

      final decryptedData = encrypter.decrypt64(encryptedData);
      return json.decode(decryptedData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> clearCachedOrderSummary(String sessionId) async {
    try {
      return await sharedPreferences.remove('$_orderSummaryPrefix$sessionId');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> getDeviceFingerprint() async {
    try {
      final fingerprint = sharedPreferences.getString(_deviceFingerprintKey);
      if (fingerprint != null) return fingerprint;

      // Generate new fingerprint if not exists
      final newFingerprint = _generateDeviceFingerprint();
      await saveDeviceFingerprint(newFingerprint);
      return newFingerprint;
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  Future<bool> saveDeviceFingerprint(String fingerprint) async {
    try {
      return await sharedPreferences.setString(_deviceFingerprintKey, fingerprint);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> saveSessionToken(String sessionId, String token) async {
    try {
      final encryptedToken = encrypter.encrypt(token);
      return await sharedPreferences.setString(
        '$_tokenPrefix$sessionId',
        encryptedToken.base64,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getSessionToken(String sessionId) async {
    try {
      final encryptedToken = sharedPreferences.getString('$_tokenPrefix$sessionId');
      if (encryptedToken == null) return null;

      return encrypter.decrypt64(encryptedToken);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> removeSessionToken(String sessionId) async {
    try {
      return await sharedPreferences.remove('$_tokenPrefix$sessionId');
    } catch (e) {
      return false;
    }
  }

  String _generateDeviceFingerprint() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().hashCode.toString();
    final combined = '$timestamp$random';

    return sha256.convert(utf8.encode(combined)).toString();
  }

  // Cleanup expired sessions
  Future<void> cleanupExpiredSessions() async {
    try {
      final sessions = await getAllSessions();
      for (final session in sessions) {
        if (session.isExpired) {
          await removeSession(session.sessionId);
        }
      }
    } catch (e) {
      // Log error but don't fail
      print('Error cleaning up expired sessions: $e');
    }
  }

  // Get sessions by user ID
  Future<List<CheckoutSessionModel>> getUserSessions(String userId) async {
    try {
      final allSessions = await getAllSessions();
      return allSessions.where((session) => session.userId == userId).toList();
    } catch (e) {
      return [];
    }
  }

  // Get abandoned sessions
  Future<List<CheckoutSessionModel>> getAbandonedSessions() async {
    try {
      final allSessions = await getAllSessions();
      return allSessions.where((session) => session.isAbandoned).toList();
    } catch (e) {
      return [];
    }
  }
}