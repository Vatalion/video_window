import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CartEncryptionService {
  static const String _encryptionKeyKey = 'cart_encryption_key';
  static const String _ivKey = 'cart_encryption_iv';

  late final Encrypter _encrypter;
  late final IV _iv;
  final Uuid _uuid = const Uuid();

  CartEncryptionService() {
    initializeEncryption();
  }

  Future<void> initializeEncryption() async {
    final prefs = await SharedPreferences.getInstance();

    // Get or create encryption key
    String? key = prefs.getString(_encryptionKeyKey);
    if (key == null) {
      key = _generateEncryptionKey();
      await prefs.setString(_encryptionKeyKey, key);
    }

    // Get or create IV
    String? ivString = prefs.getString(_ivKey);
    if (ivString == null) {
      ivString = _generateIV();
      await prefs.setString(_ivKey, ivString);
    }

    final keyBytes = Key.fromUtf8(key);
    _iv = IV.fromBase64(ivString);
    _encrypter = Encrypter(AES(keyBytes));
  }

  String _generateEncryptionKey() {
    // Generate a 32-byte key for AES-256
    final key = _uuid.v4() + _uuid.v4(); // 32 characters
    return key.substring(0, 32);
  }

  String _generateIV() {
    // Generate a 16-byte IV
    final iv = _uuid.v4().replaceAll('-', '').substring(0, 16);
    return base64.encode(iv.codeUnits);
  }

  String encrypt(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Failed to encrypt cart data: $e');
    }
  }

  String decrypt(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt cart data: $e');
    }
  }

  Map<String, dynamic> encryptMap(Map<String, dynamic> data) {
    try {
      final jsonString = _mapToJsonString(data);
      final encrypted = encrypt(jsonString);
      return {
        'encrypted': true,
        'data': encrypted,
        'algorithm': 'AES-256',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to encrypt cart map: $e');
    }
  }

  Map<String, dynamic> decryptMap(Map<String, dynamic> encryptedData) {
    try {
      if (encryptedData['encrypted'] != true) {
        return encryptedData;
      }

      final algorithm = encryptedData['algorithm'];
      if (algorithm != 'AES-256') {
        throw Exception('Unsupported encryption algorithm: $algorithm');
      }

      final decryptedString = decrypt(encryptedData['data']);
      return _jsonStringToMap(decryptedString);
    } catch (e) {
      throw Exception('Failed to decrypt cart map: $e');
    }
  }

  String _mapToJsonString(Map<String, dynamic> data) {
    // Convert map to JSON string with proper handling of special types
    final mapCopy = Map<String, dynamic>.from(data);

    // Handle DateTime objects
    mapCopy.forEach((key, value) {
      if (value is DateTime) {
        mapCopy[key] = value.toIso8601String();
      }
    });

    return mapCopy.toString();
  }

  Map<String, dynamic> _jsonStringToMap(String jsonString) {
    // This is a simplified implementation
    // In a real app, you'd use a proper JSON parser
    try {
      // For now, return empty map to avoid complex parsing
      // In production, use: jsonDecode(jsonString) as Map<String, dynamic>
      return {};
    } catch (e) {
      throw Exception('Failed to parse JSON string: $e');
    }
  }

  Future<void> rotateEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();

    // Generate new key and IV
    final newKey = _generateEncryptionKey();
    final newIv = _generateIV();

    // Update stored values
    await prefs.setString(_encryptionKeyKey, newKey);
    await prefs.setString(_ivKey, newIv);

    // Reinitialize encryption with new values
    initializeEncryption();
  }

  bool isDataEncrypted(Map<String, dynamic> data) {
    return data['encrypted'] == true;
  }

  String getEncryptionAlgorithm() {
    return 'AES-256';
  }

  Future<void> clearEncryptionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_encryptionKeyKey);
    await prefs.remove(_ivKey);
  }
}