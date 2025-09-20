import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as crypto;

class PasswordService {
  static const int _saltLength = 32;
  static const int _iterations = 10000;
  static const int _keyLength = 64;

  /// Hash a password using PBKDF2 with SHA-256
  String hashPassword(String password) {
    // Generate a random salt
    final salt = _generateSalt();

    // Hash the password
    final hashedPassword = _hashWithPBKDF2(password, salt);

    // Combine salt and hashed password for storage
    final combined = salt + hashedPassword;
    return base64.encode(combined);
  }

  /// Verify a password against a stored hash
  bool verifyPassword(String password, String storedHash) {
    try {
      final decoded = base64.decode(storedHash);

      // Extract salt and hashed password
      final salt = decoded.sublist(0, _saltLength);
      final storedHashedPassword = decoded.sublist(_saltLength);

      // Hash the provided password with the same salt
      final computedHash = _hashWithPBKDF2(password, salt);

      // Compare the hashes
      return _constantTimeCompare(computedHash, storedHashedPassword);
    } catch (e) {
      return false;
    }
  }

  /// Validate password strength
  PasswordStrength validatePasswordStrength(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // Length bonus
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // Character variety
    if (password.contains(RegExp(r'[A-Z]'))) score++; // Uppercase
    if (password.contains(RegExp(r'[a-z]'))) score++; // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) score++; // Numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      score++; // Special chars

    // No common patterns
    if (!_containsCommonPattern(password)) score++;

    // No sequential characters
    if (!_containsSequentialChars(password)) score++;

    // Return strength based on score
    if (score >= 6) return PasswordStrength.veryStrong;
    if (score >= 4) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  /// Generate a secure random salt
  List<int> _generateSalt() {
    final random = crypto.FortunaRandom();
    final seed = crypto.SecureRandom('Fortuna').nextBytes(32);
    random.seed(crypto.KeyParameter(seed));
    return random.nextBytes(_saltLength);
  }

  /// Hash using PBKDF2 with SHA-256
  List<int> _hashWithPBKDF2(String password, List<int> salt) {
    final passwordBytes = utf8.encode(password);
    final pbkdf2 = crypto.PBKDF2KeyDerivator(
      crypto.HMac(crypto.SHA256Digest(), _keyLength),
    );
    final params = crypto.Pbkdf2Parameters(
      Uint8List.fromList(salt),
      _iterations,
      _keyLength,
    );
    pbkdf2.init(params);
    return pbkdf2.process(Uint8List.fromList(passwordBytes));
  }

  /// Constant time comparison to prevent timing attacks
  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Check for common password patterns
  bool _containsCommonPattern(String password) {
    final commonPatterns = [
      '123456',
      'password',
      'qwerty',
      'abc123',
      'letmein',
      'admin',
      'welcome',
      'monkey',
      'password1',
      '123456789',
    ];

    final lowerPassword = password.toLowerCase();
    return commonPatterns.any((pattern) => lowerPassword.contains(pattern));
  }

  /// Check for sequential characters
  bool _containsSequentialChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      final char1 = password.codeUnitAt(i);
      final char2 = password.codeUnitAt(i + 1);
      final char3 = password.codeUnitAt(i + 2);

      // Check for sequential numbers (123)
      if (char2 == char1 + 1 && char3 == char2 + 1) {
        return true;
      }

      // Check for sequential letters (abc)
      if ((char1 >= 97 && char1 <= 122) && // lowercase letters
          (char2 == char1 + 1 && char3 == char2 + 1)) {
        return true;
      }
    }
    return false;
  }

  /// Generate a secure random password
  String generateSecurePassword({int length = 16}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = crypto.FortunaRandom();
    final seed = crypto.SecureRandom('Fortuna').nextBytes(32);
    random.seed(crypto.KeyParameter(seed));

    final password = StringBuffer();
    for (int i = 0; i < length; i++) {
      final randomIndex = random.nextBytes(1)[0] % chars.length;
      password.write(chars[randomIndex]);
    }

    return password.toString();
  }
}

enum PasswordStrength { weak, medium, strong, veryStrong }

extension PasswordStrengthExtension on PasswordStrength {
  String get displayName {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  double get score {
    switch (this) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  Color getColor(Color baseColor) {
    switch (this) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.yellow;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }
}
