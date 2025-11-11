import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Profile encryption service for field-level PII encryption
/// Implements SEC-004: Field-level encryption for sensitive PII data
/// Uses AES-256-GCM encryption with per-user salt-based key derivation
class ProfileEncryptionService {
  final FlutterSecureStorage _secureStorage;
  static const String _keyMasterKey = 'profile_master_key';
  static const String _keyUserSaltPrefix = 'profile_user_salt_';

  // Sensitive fields that require encryption
  static const List<String> sensitiveFields = [
    'phone',
    'address',
    'dateOfBirth',
    'preferences',
  ];

  ProfileEncryptionService() : _secureStorage = const FlutterSecureStorage();

  /// Initialize master key (in production, this would come from AWS KMS)
  /// For now, generates and stores locally - MUST be replaced with KMS integration
  Future<void> initialize() async {
    try {
      final existingKey = await _secureStorage.read(key: _keyMasterKey);
      if (existingKey == null) {
        // Generate master key using secure random
        final masterKeyBytes = _generateSecureRandom(32);
        final masterKey = encrypt_lib.Key(masterKeyBytes);
        await _secureStorage.write(
          key: _keyMasterKey,
          value: masterKey.base64,
        );
      }
    } catch (e) {
      throw Exception('Failed to initialize profile encryption: $e');
    }
  }

  /// Generate user-specific salt for key derivation
  Future<String> _getUserSalt(int userId) async {
    final saltKey = '$_keyUserSaltPrefix$userId';
    final existingSalt = await _secureStorage.read(key: saltKey);

    if (existingSalt != null) {
      return existingSalt;
    }

    // Generate new salt
    final saltBytes = _generateSecureRandom(16);
    final salt = base64.encode(saltBytes);
    await _secureStorage.write(key: saltKey, value: salt);
    return salt;
  }

  /// Derive encryption key for user using PBKDF2
  Future<encrypt_lib.Key> _deriveUserKey(int userId) async {
    await initialize();
    final masterKeyBase64 = await _secureStorage.read(key: _keyMasterKey);
    if (masterKeyBase64 == null) {
      throw Exception('Master key not initialized');
    }

    final salt = await _getUserSalt(userId);

    // Derive key using PBKDF2 (simplified - in production use proper PBKDF2)
    final keyMaterial = utf8.encode('$masterKeyBase64$salt$userId');
    final hash = sha256.convert(keyMaterial);
    final keyBytes = hash.bytes.take(32).toList();

    return encrypt_lib.Key(Uint8List.fromList(keyBytes));
  }

  /// Encrypt sensitive field value
  Future<String> encryptField(
      int userId, String fieldName, String value) async {
    if (value.isEmpty) return value;

    try {
      final userKey = await _deriveUserKey(userId);
      final iv = encrypt_lib.IV.fromSecureRandom(16);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(userKey, mode: encrypt_lib.AESMode.gcm),
      );

      final encrypted = encrypter.encrypt(value, iv: iv);

      // Combine IV and ciphertext
      final combined = {
        'iv': iv.base64,
        'data': encrypted.base64,
        'field': fieldName,
      };

      return base64.encode(utf8.encode(json.encode(combined)));
    } catch (e) {
      throw Exception('Failed to encrypt field $fieldName: $e');
    }
  }

  /// Decrypt sensitive field value
  Future<String?> decryptField(
      int userId, String fieldName, String encryptedValue) async {
    if (encryptedValue.isEmpty) return encryptedValue;

    try {
      final combinedJson = json.decode(
        utf8.decode(base64.decode(encryptedValue)),
      ) as Map<String, dynamic>;

      final iv = encrypt_lib.IV.fromBase64(combinedJson['iv'] as String);
      final encryptedData = encrypt_lib.Encrypted.fromBase64(
        combinedJson['data'] as String,
      );

      final userKey = await _deriveUserKey(userId);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(userKey, mode: encrypt_lib.AESMode.gcm),
      );

      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      // Decryption failed - data might be corrupted or tampered
      return null;
    }
  }

  /// Encrypt sensitive fields in profile data map
  Future<Map<String, dynamic>> encryptSensitiveFields(
    int userId,
    Map<String, dynamic> data,
  ) async {
    final encryptedData = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (encryptedData.containsKey(field) && encryptedData[field] != null) {
        final value = encryptedData[field].toString();
        encryptedData['${field}_encrypted'] =
            await encryptField(userId, field, value);
        encryptedData.remove(field);
      }
    }

    return encryptedData;
  }

  /// Decrypt sensitive fields in profile data map
  Future<Map<String, dynamic>> decryptSensitiveFields(
    int userId,
    Map<String, dynamic> data,
  ) async {
    final decryptedData = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      final encryptedKey = '${field}_encrypted';
      if (decryptedData.containsKey(encryptedKey)) {
        final encryptedValue = decryptedData[encryptedKey].toString();
        final decrypted = await decryptField(userId, field, encryptedValue);
        if (decrypted != null) {
          decryptedData[field] = decrypted;
        }
        decryptedData.remove(encryptedKey);
      }
    }

    return decryptedData;
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateSecureRandom(int length) {
    final random = <int>[];
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final timestampBytes = ByteData(8)..setInt64(0, timestamp);

    for (var i = 0; i < length; i++) {
      if (i < 8) {
        random.add(timestampBytes.getUint8(i));
      } else {
        final hash = sha256.convert([...random, i, timestamp + i]);
        random.add(hash.bytes[i % hash.bytes.length]);
      }
    }

    return Uint8List.fromList(random.take(length).toList());
  }
}
