import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:typed_data';

class CheckoutEncryptionService {
  final String _encryptionKey;
  final Encrypter _encrypter;

  CheckoutEncryptionService(this._encryptionKey)
      : _encrypter = Encrypter(AES(Key.fromUtf8(_encryptionKey.padRight(32, '0').substring(0, 32))));

  // String encryption/decryption
  String encryptString(String plaintext) {
    try {
      final iv = IV.fromLength(16);
      final encrypted = _encrypter.encrypt(plaintext, iv: iv);
      return iv.base64 + ':' + encrypted.base64;
    } catch (e) {
      throw EncryptionException('Failed to encrypt string: $e');
    }
  }

  String decryptString(String encryptedText) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw EncryptionException('Invalid encrypted format');
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw EncryptionException('Failed to decrypt string: $e');
    }
  }

  // JSON encryption/decryption
  String encryptJson(Map<String, dynamic> json) {
    try {
      final jsonString = jsonEncode(json);
      return encryptString(jsonString);
    } catch (e) {
      throw EncryptionException('Failed to encrypt JSON: $e');
    }
  }

  Map<String, dynamic> decryptJson(String encryptedJson) {
    try {
      final jsonString = decryptString(encryptedJson);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw EncryptionException('Failed to decrypt JSON: $e');
    }
  }

  // Sensitive data masking
  String maskCreditCard(String cardNumber) {
    if (cardNumber.length < 4) return '****';

    final lastFour = cardNumber.substring(cardNumber.length - 4);
    return '****-****-****-$lastFour';
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '****';

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}****@$domain';
    } else {
      final maskedUsername = '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
      return '$maskedUsername@$domain';
    }
  }

  String maskPhoneNumber(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 4) return '****';

    final lastFour = cleanPhone.substring(cleanPhone.length - 4);
    return '***-***-$lastFour';
  }

  // Hashing functions
  String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String generateSecureToken() {
    return const Uuid().v4();
  }

  // PCI compliance helpers
  bool isValidCreditCard(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Basic length check
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhn algorithm
    return _luhnCheck(cleanNumber);
  }

  bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10) == 0;
  }

  // Data integrity verification
  String generateDataIntegrityHash(Map<String, dynamic> data) {
    try {
      final sortedKeys = data.keys.toList()..sort();
      final concatenated = sortedKeys.map((key) => '$key:${data[key]}').join('|');
      return sha256Hash(concatenated);
    } catch (e) {
      throw EncryptionException('Failed to generate integrity hash: $e');
    }
  }

  bool verifyDataIntegrity(Map<String, dynamic> data, String hash) {
    try {
      final calculatedHash = generateDataIntegrityHash(data);
      return calculatedHash == hash;
    } catch (e) {
      return false;
    }
  }

  // Secure key generation
  String generateEncryptionKey() {
    final random = SecureRandom(Random.secure());
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(keyBytes);
  }

  // Tokenization for sensitive data
  String tokenize(String sensitiveData) {
    final token = generateSecureToken();
    // In a real implementation, this would store the mapping securely
    // For now, we'll return a hash of the data
    return sha256Hash(sensitiveData);
  }

  // Secure timestamp verification
  bool isValidTimestamp(String timestamp, Duration maxAge) {
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final age = now.difference(time);
      return age <= maxAge && age >= Duration.zero;
    } catch (e) {
      return false;
    }
  }

  // Data sanitization for logging
  Map<String, dynamic> sanitizeForLogging(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Remove or mask sensitive fields
    final sensitiveFields = [
      'creditCard', 'cardNumber', 'cvv', 'expiry', 'password',
      'securityCode', 'cardToken', 'ssn', 'socialSecurity'
    ];

    for (final field in sensitiveFields) {
      if (sanitized.containsKey(field)) {
        sanitized[field] = '****';
      }
    }

    return sanitized;
  }
}

class EncryptionException implements Exception {
  final String message;

  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}