import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';

class CartStorageService {
  static const String _boxName = 'cart_box';
  static const String _encryptionKey = 'your-secret-encryption-key-32-chars-long';

  late Box _cartBox;
  final Encrypter _encrypter;

  CartStorageService() : _encrypter = Encrypter(AES(Key.fromUtf8(_encryptionKey))) {
    _initStorage();
  }

  Future<void> _initStorage() async {
    await Hive.initFlutter();
    _cartBox = await Hive.openBox(_boxName);
  }

  Future<void> saveCart(Cart cart) async {
    try {
      final encryptedData = _encryptCartData(cart.toJson());
      await _cartBox.put(cart.sessionId, encryptedData);

      if (!cart.isAnonymous && cart.userId.isNotEmpty) {
        await _saveCartToServer(cart);
      }

      await _createCartBackup(cart);
    } catch (e) {
      throw Exception('Failed to save cart: $e');
    }
  }

  Future<Cart?> loadCartFromLocalStorage(String sessionId) async {
    try {
      final encryptedData = _cartBox.get(sessionId);
      if (encryptedData == null) return null;

      final decryptedData = _decryptCartData(encryptedData);
      return Cart.fromJson(decryptedData);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load cart from local storage: $e');
      }
      return null;
    }
  }

  Future<Cart?> loadCartFromServer(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/carts/user/$userId'),
        headers: {'Authorization': 'Bearer ${await _getAuthToken()}'},
      );

      if (response.statusCode == 200) {
        return Cart.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load cart from server: $e');
      }
      return null;
    }
  }

  Future<void> _saveCartToServer(Cart cart) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.example.com/carts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode(cart.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save cart to server: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save cart to server: $e');
      }
    }
  }

  Future<void> _createCartBackup(Cart cart) async {
    try {
      final backupData = {
        'cart': cart.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final backupFile = File('/tmp/cart_backup_${cart.sessionId}_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(jsonEncode(backupData));

      await _cleanupOldBackups(cart.sessionId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create cart backup: $e');
      }
    }
  }

  Future<void> _cleanupOldBackups(String sessionId) async {
    try {
      final tempDir = Directory('/tmp');
      final files = await tempDir.list().where((entity) =>
        entity is File && entity.path.contains('cart_backup_$sessionId')).cast<File>().toList();

      if (files.length > 30) {
        files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        final filesToDelete = files.sublist(0, files.length - 30);

        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup old backups: $e');
      }
    }
  }

  Future<void> clearAnonymousCarts() async {
    try {
      final keysToDelete = <String>[];

      for (final key in _cartBox.keys) {
        final encryptedData = _cartBox.get(key);
        if (encryptedData != null) {
          final cartData = _decryptCartData(encryptedData);
          final cart = Cart.fromJson(cartData);

          if (cart.isAnonymous &&
              cart.sessionExpiresAt != null &&
              cart.sessionExpiresAt!.isBefore(DateTime.now())) {
            keysToDelete.add(key.toString());
          }
        }
      }

      for (final key in keysToDelete) {
        await _cartBox.delete(key);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear anonymous carts: $e');
      }
    }
  }

  Future<String> _getAuthToken() async {
    return 'user-auth-token';
  }

  String _encryptCartData(Map<String, dynamic> data) {
    final iv = IV.fromLength(16);
    final encrypted = _encrypter.encrypt(jsonEncode(data), iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  Map<String, dynamic> _decryptCartData(String encryptedData) {
    final parts = encryptedData.split(':');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final decrypted = _encrypter.decrypt(encrypted, iv: iv);
    return jsonDecode(decrypted);
  }

  Future<void> close() async {
    await _cartBox.close();
  }
}