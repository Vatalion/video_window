import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/shopping_cart.dart';
import '../models/cart_item.dart';
import 'cart_database.dart';
import 'cart_encryption_service.dart';
import 'cart_sync_service.dart';

class CartService {
  final CartDatabase _database = CartDatabase();
  final CartEncryptionService _encryptionService = CartEncryptionService();
  final CartSyncService _syncService = CartSyncService();
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  ShoppingCart? _currentCart;
  StreamSubscription<ShoppingCart>? _syncSubscription;

  Future<void> initialize() async {
    await _database.init();
    await _encryptionService._initializeEncryption();
    await _syncService.initialize();
    _setupSyncListeners();
    _startCleanupTimer();
  }

  void _setupSyncListeners() {
    _syncSubscription = _syncService.cartUpdates.listen((updatedCart) {
      if (_currentCart != null && updatedCart.id == _currentCart!.id) {
        _currentCart = updatedCart;
        _saveCartToLocalStorage(updatedCart);
      }
    });
  }

  void _startCleanupTimer() {
    Timer.periodic(const Duration(hours: 1), (timer) async {
      try {
        await _database.cleanupExpiredCarts();
        _logger.i('Expired carts cleanup completed');
      } catch (e) {
        _logger.e('Error during expired carts cleanup: $e');
      }
    });
  }

  Future<ShoppingCart> getCart({String? userId, String? sessionId}) async {
    try {
      // Try to get cart from user ID first
      if (userId != null) {
        final cartData = await _database.getCartByUser(userId);
        if (cartData != null) {
          _currentCart = ShoppingCart.fromJson(cartData);
          return _currentCart!;
        }
      }

      // Try to get cart from session ID
      if (sessionId != null) {
        final cartData = await _database.getCartBySession(sessionId);
        if (cartData != null) {
          _currentCart = ShoppingCart.fromJson(cartData);
          return _currentCart!;
        }
      }

      // Create new cart if none found
      final newCart = ShoppingCart.empty(
        userId: userId ?? _uuid.v4(),
        sessionId: sessionId ?? _uuid.v4(),
        isAnonymous: userId == null,
      );

      _currentCart = newCart;
      await _saveCartToLocalStorage(newCart);
      return newCart;
    } catch (e) {
      _logger.e('Error getting cart: $e');
      throw Exception('Failed to get cart: $e');
    }
  }

  Future<ShoppingCart> addToCart(CartItem item, {String? userId, String? sessionId}) async {
    try {
      final cart = await getCart(userId: userId, sessionId: sessionId);
      final updatedCart = cart.addItem(item);

      await _saveCartAndSync(updatedCart);
      _logger.i('Item added to cart: ${item.name}');
      return updatedCart;
    } catch (e) {
      _logger.e('Error adding item to cart: $e');
      throw Exception('Failed to add item to cart: $e');
    }
  }

  Future<ShoppingCart> removeFromCart(String itemId, {String? userId, String? sessionId}) async {
    try {
      final cart = await getCart(userId: userId, sessionId: sessionId);
      final updatedCart = cart.removeItem(itemId);

      await _saveCartAndSync(updatedCart);
      _logger.i('Item removed from cart: $itemId');
      return updatedCart;
    } catch (e) {
      _logger.e('Error removing item from cart: $e');
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  Future<ShoppingCart> updateQuantity(String itemId, int quantity, {String? userId, String? sessionId}) async {
    try {
      final cart = await getCart(userId: userId, sessionId: sessionId);
      final updatedCart = cart.updateQuantity(itemId, quantity);

      await _saveCartAndSync(updatedCart);
      _logger.i('Item quantity updated: $itemId -> $quantity');
      return updatedCart;
    } catch (e) {
      _logger.e('Error updating item quantity: $e');
      throw Exception('Failed to update item quantity: $e');
    }
  }

  Future<ShoppingCart> clearCart({String? userId, String? sessionId}) async {
    try {
      final cart = await getCart(userId: userId, sessionId: sessionId);
      final updatedCart = cart.clear();

      await _saveCartAndSync(updatedCart);
      _logger.i('Cart cleared for user: ${cart.userId}');
      return updatedCart;
    } catch (e) {
      _logger.e('Error clearing cart: $e');
      throw Exception('Failed to clear cart: $e');
    }
  }

  Future<ShoppingCart> applyCoupon(String couponCode, {String? userId, String? sessionId}) async {
    try {
      final cart = await getCart(userId: userId, sessionId: sessionId);
      // This would typically involve calling a backend service
      // For now, we'll just apply a fixed discount
      final discountAmount = cart.subtotal * 0.1; // 10% discount
      final newTotal = cart.total - discountAmount;

      final updatedCart = cart.copyWith(
        couponCode: couponCode,
        discountAmount: discountAmount,
        total: newTotal,
      );

      await _saveCartAndSync(updatedCart);
      _logger.i('Coupon applied: $couponCode, discount: \$$discountAmount');
      return updatedCart;
    } catch (e) {
      _logger.e('Error applying coupon: $e');
      throw Exception('Failed to apply coupon: $e');
    }
  }

  Future<ShoppingCart> mergeCarts(ShoppingCart sourceCart, ShoppingCart targetCart) async {
    try {
      ShoppingCart mergedCart = targetCart;

      // Merge items from source to target
      for (final item in sourceCart.items) {
        mergedCart = mergedCart.addItem(item);
      }

      // Keep the target cart's ID and metadata
      mergedCart = mergedCart.copyWith(
        id: targetCart.id,
        userId: targetCart.userId,
        sessionId: targetCart.sessionId,
        isAnonymous: targetCart.isAnonymous,
        createdAt: targetCart.createdAt,
      );

      await _saveCartAndSync(mergedCart);

      // Delete the source cart
      await _database.deleteCart(sourceCart.id);

      _logger.i('Carts merged: ${sourceCart.id} -> ${targetCart.id}');
      return mergedCart;
    } catch (e) {
      _logger.e('Error merging carts: $e');
      throw Exception('Failed to merge carts: $e');
    }
  }

  Future<void> extendSession(String sessionId, Duration extension) async {
    try {
      final cartData = await _database.getCartBySession(sessionId);
      if (cartData != null) {
        final cart = ShoppingCart.fromJson(cartData);
        final newExpiresAt = cart.expiresAt.add(extension);
        final updatedCart = cart.copyWith(expiresAt: newExpiresAt);

        await _saveCartAndSync(updatedCart);
        _logger.i('Session extended: $sessionId, new expiry: $newExpiresAt');
      }
    } catch (e) {
      _logger.e('Error extending session: $e');
      throw Exception('Failed to extend session: $e');
    }
  }

  Future<void> _saveCartToLocalStorage(ShoppingCart cart) async {
    try {
      final cartData = cart.toJson();
      final encryptedData = _encryptionService.encryptMap(cartData);
      await _database.saveCart(encryptedData);
    } catch (e) {
      _logger.e('Error saving cart to local storage: $e');
      throw Exception('Failed to save cart to local storage: $e');
    }
  }

  Future<void> _saveCartAndSync(ShoppingCart cart) async {
    try {
      // Save to local storage first
      await _saveCartToLocalStorage(cart);

      // Update sync status to pending
      await _database.updateSyncStatus(cart.id, 'pending');

      // Sync with server
      await _syncService.syncCart(cart);

      // Update current cart reference
      _currentCart = cart;
    } catch (e) {
      _logger.e('Error saving and syncing cart: $e');
      throw Exception('Failed to save and sync cart: $e');
    }
  }

  Future<List<ShoppingCart>> getCartsForBackup() async {
    try {
      final pendingCarts = await _database.getPendingSyncCarts();
      return pendingCarts.map((data) => ShoppingCart.fromJson(data)).toList();
    } catch (e) {
      _logger.e('Error getting carts for backup: $e');
      throw Exception('Failed to get carts for backup: $e');
    }
  }

  Future<void> backupCart(ShoppingCart cart) async {
    try {
      final encryptedData = _encryptionService.encryptMap(cart.toJson());
      // In a real implementation, this would save to cloud storage
      _logger.i('Cart backed up: ${cart.id}');
    } catch (e) {
      _logger.e('Error backing up cart: $e');
      throw Exception('Failed to backup cart: $e');
    }
  }

  Future<ShoppingCart?> restoreCart(String cartId) async {
    try {
      // In a real implementation, this would restore from cloud storage
      final cartData = await _database.getCart(cartId);
      if (cartData != null) {
        final cart = ShoppingCart.fromJson(cartData);
        _currentCart = cart;
        _logger.i('Cart restored: $cartId');
        return cart;
      }
      return null;
    } catch (e) {
      _logger.e('Error restoring cart: $e');
      throw Exception('Failed to restore cart: $e');
    }
  }

  Stream<ShoppingCart> get cartStream => _syncService.cartUpdates;

  ShoppingCart? get currentCart => _currentCart;

  Future<void> dispose() async {
    await _syncSubscription?.cancel();
    await _syncService.dispose();
    await _database.close();
    _logger.i('Cart service disposed');
  }
}