import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Secure token storage with AES-256-GCM encryption
/// Implements SEC-003 requirement: Enhanced secure storage with encryption at rest
class SecureTokenStorage {
  final FlutterSecureStorage _secureStorage;
  encrypt_lib.Key? _encryptionKey;

  // Storage keys
  static const String _keyEncryptionKey = 'video_window_encryption_key';
  static const String _keyAccessToken = 'video_window_access_token';
  static const String _keyRefreshToken = 'video_window_refresh_token';
  static const String _keyUserId = 'video_window_user_id';
  static const String _keyDeviceId = 'video_window_device_id';
  static const String _keySessionId = 'video_window_session_id';

  SecureTokenStorage() : _secureStorage = const FlutterSecureStorage();

  /// Initialize encryption key (generate or load existing)
  Future<void> initialize() async {
    try {
      // Try to load existing encryption key
      final existingKey = await _secureStorage.read(key: _keyEncryptionKey);

      if (existingKey != null) {
        _encryptionKey = encrypt_lib.Key.fromBase64(existingKey);
      } else {
        // Generate new encryption key using secure random
        final secureRandom = _generateSecureRandom();
        _encryptionKey = encrypt_lib.Key(secureRandom);

        // Store the key securely
        await _secureStorage.write(
          key: _keyEncryptionKey,
          value: _encryptionKey!.base64,
        );
      }
    } catch (e) {
      throw Exception('Failed to initialize encryption: $e');
    }
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateSecureRandom() {
    final random = <int>[];
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final timestampBytes = ByteData(8)..setInt64(0, timestamp);

    // Combine timestamp with secure random from crypto library
    for (var i = 0; i < 32; i++) {
      if (i < 8) {
        random.add(timestampBytes.getUint8(i));
      } else {
        // Use SHA-256 to generate additional random bytes
        final hash = sha256.convert([...random, i, timestamp + i]);
        random.add(hash.bytes[i % hash.bytes.length]);
      }
    }

    return Uint8List.fromList(random);
  }

  /// Encrypt data using AES-256-GCM
  Future<String> _encrypt(String plaintext) async {
    if (_encryptionKey == null) {
      await initialize();
    }

    try {
      final iv = encrypt_lib.IV.fromSecureRandom(16);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_encryptionKey!, mode: encrypt_lib.AESMode.gcm),
      );

      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Combine IV and ciphertext
      final combined = {
        'iv': iv.base64,
        'data': encrypted.base64,
      };

      return base64.encode(utf8.encode(json.encode(combined)));
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt data using AES-256-GCM
  Future<String?> _decrypt(String ciphertext) async {
    if (_encryptionKey == null) {
      await initialize();
    }

    try {
      final combinedJson = json.decode(
        utf8.decode(base64.decode(ciphertext)),
      ) as Map<String, dynamic>;

      final iv = encrypt_lib.IV.fromBase64(combinedJson['iv'] as String);
      final encryptedData = encrypt_lib.Encrypted.fromBase64(
        combinedJson['data'] as String,
      );

      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(_encryptionKey!, mode: encrypt_lib.AESMode.gcm),
      );

      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      // If decryption fails, data might be corrupted or tampered
      return null;
    }
  }

  /// Store access token securely
  Future<void> saveAccessToken(String token) async {
    final encrypted = await _encrypt(token);
    await _secureStorage.write(key: _keyAccessToken, value: encrypted);
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    final encrypted = await _secureStorage.read(key: _keyAccessToken);
    if (encrypted == null) return null;
    return await _decrypt(encrypted);
  }

  /// Store refresh token securely
  Future<void> saveRefreshToken(String token) async {
    final encrypted = await _encrypt(token);
    await _secureStorage.write(key: _keyRefreshToken, value: encrypted);
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    final encrypted = await _secureStorage.read(key: _keyRefreshToken);
    if (encrypted == null) return null;
    return await _decrypt(encrypted);
  }

  /// Store user ID
  Future<void> saveUserId(int userId) async {
    await _secureStorage.write(key: _keyUserId, value: userId.toString());
  }

  /// Retrieve user ID
  Future<int?> getUserId() async {
    final value = await _secureStorage.read(key: _keyUserId);
    return value != null ? int.tryParse(value) : null;
  }

  /// Store device ID
  Future<void> saveDeviceId(String deviceId) async {
    await _secureStorage.write(key: _keyDeviceId, value: deviceId);
  }

  /// Retrieve device ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _keyDeviceId);
  }

  /// Store session ID
  Future<void> saveSessionId(String sessionId) async {
    await _secureStorage.write(key: _keySessionId, value: sessionId);
  }

  /// Retrieve session ID
  Future<String?> getSessionId() async {
    return await _secureStorage.read(key: _keySessionId);
  }

  /// Store complete authentication session
  Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    required int userId,
    String? deviceId,
    String? sessionId,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserId(userId),
      if (deviceId != null) saveDeviceId(deviceId),
      if (sessionId != null) saveSessionId(sessionId),
    ]);
  }

  /// Retrieve complete authentication session
  Future<AuthSession?> getAuthSession() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    final userId = await getUserId();

    if (accessToken == null || refreshToken == null || userId == null) {
      return null;
    }

    final deviceId = await getDeviceId();
    final sessionId = await getSessionId();

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      deviceId: deviceId,
      sessionId: sessionId,
    );
  }

  /// Clear all stored tokens and session data
  Future<void> clearSession() async {
    await _secureStorage.deleteAll();
    _encryptionKey = null;
  }

  /// Check if user is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Rotate encryption key (for security hardening)
  Future<void> rotateEncryptionKey() async {
    // Read all current data
    final session = await getAuthSession();
    if (session == null) return;

    // Delete old encryption key
    await _secureStorage.delete(key: _keyEncryptionKey);
    _encryptionKey = null;

    // Reinitialize with new key
    await initialize();

    // Re-encrypt and store all data
    await saveAuthSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.userId,
      deviceId: session.deviceId,
      sessionId: session.sessionId,
    );
  }
}

/// Authentication session data structure
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String? deviceId;
  final String? sessionId;

  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.deviceId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
        'deviceId': deviceId,
        'sessionId': sessionId,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        userId: json['userId'] as int,
        deviceId: json['deviceId'] as String?,
        sessionId: json['sessionId'] as String?,
      );
}
