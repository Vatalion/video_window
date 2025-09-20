import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';
import 'cart_storage_service.dart';
import 'cart_sync_service.dart';
import 'cart_analytics_service.dart';

class CartService extends ChangeNotifier {
  Cart? _currentCart;
  bool _isLoading = false;
  String? _error;
  CartStorageService _storageService;
  CartSyncService _syncService;
  CartAnalyticsService _analyticsService;
  WebSocketChannel? _socketChannel;

  Cart? get currentCart => _currentCart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CartService(this._storageService, this._syncService, this._analyticsService);

  Future<void> initializeCart({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sessionId = _generateSessionId();
      final deviceToken = _generateDeviceToken();

      Cart cart;

      if (userId != null) {
        cart = await _storageService.loadCartFromServer(userId) ??
               await _loadAnonymousCartAndConvert(sessionId, deviceToken, userId);
      } else {
        cart = await _storageService.loadCartFromLocalStorage(sessionId) ??
               _createNewCart(sessionId, deviceToken);
      }

      _currentCart = cart;

      _analyticsService.trackCartViewed(cart);
      await _connectWebSocket(sessionId);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize cart: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(CartItem item) async {
    if (_currentCart == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final oldCart = _currentCart!;
      final updatedCart = oldCart.addItem(item);
      await _storageService.saveCart(updatedCart);
      _currentCart = updatedCart;

      _analyticsService.trackItemAdded(item, updatedCart);
      _broadcastCartUpdate();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add item: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(String itemId) async {
    if (_currentCart == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final oldCart = _currentCart!;
      final removedItem = oldCart.items.firstWhere((item) => item.id == itemId);
      final updatedCart = oldCart.removeItem(itemId);
      await _storageService.saveCart(updatedCart);
      _currentCart = updatedCart;

      _analyticsService.trackItemRemoved(removedItem, updatedCart);
      _broadcastCartUpdate();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove item: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateItemQuantity(String itemId, int quantity) async {
    if (_currentCart == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final oldCart = _currentCart!;
      final oldItem = oldCart.items.firstWhere((item) => item.id == itemId);
      final updatedCart = oldCart.updateItemQuantity(itemId, quantity);
      _currentCart = updatedCart;

      _analyticsService.trackItemQuantityChanged(oldItem, oldItem.quantity, quantity, updatedCart);
      await _storageService.saveCart(updatedCart);
      _broadcastCartUpdate();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update quantity: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    if (_currentCart == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final oldCart = _currentCart!;
      final updatedCart = oldCart.clear();
      await _storageService.saveCart(updatedCart);
      _currentCart = updatedCart;

      _analyticsService.trackCartCleared(updatedCart);
      _broadcastCartUpdate();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear cart: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> mergeCart(Cart remoteCart) async {
    if (_currentCart == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final localCart = _currentCart!;
      final mergedCart = _syncService.mergeCarts(localCart, remoteCart);
      await _storageService.saveCart(mergedCart);
      _currentCart = mergedCart;

      _analyticsService.trackCartMerged(localCart, remoteCart, mergedCart);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to merge cart: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCart() async {
    if (_currentCart == null || _currentCart!.userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final remoteCart = await _storageService.loadCartFromServer(_currentCart!.userId);
      if (remoteCart != null) {
        await mergeCart(remoteCart);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh cart: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _connectWebSocket(String sessionId) async {
    try {
      _socketChannel = IOWebSocketChannel.connect(
        Uri.parse('wss://api.example.com/cart-sync?sessionId=$sessionId'),
      );

      _socketChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'cart_update') {
            final remoteCart = Cart.fromJson(data['cart']);
            if (_currentCart != null && remoteCart.updatedAt.isAfter(_currentCart!.updatedAt)) {
              mergeCart(remoteCart);
            }
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          _attemptReconnect(sessionId);
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
    }
  }

  void _broadcastCartUpdate() {
    if (_socketChannel != null && _currentCart != null) {
      _socketChannel!.sink.add(jsonEncode({
        'type': 'cart_update',
        'cart': _currentCart!.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  void _attemptReconnect(String sessionId) {
    Future.delayed(const Duration(seconds: 5), () {
      if (_currentCart?.sessionId == sessionId) {
        _connectWebSocket(sessionId);
      }
    });
  }

  Future<Cart> _loadAnonymousCartAndConvert(String sessionId, String deviceToken, String userId) async {
    final anonymousCart = await _storageService.loadCartFromLocalStorage(sessionId);
    final newCart = _createNewCart(sessionId, deviceToken, userId: userId);

    if (anonymousCart != null && anonymousCart.items.isNotEmpty) {
      final mergedCart = _syncService.mergeCarts(newCart, anonymousCart);
      await _storageService.saveCart(mergedCart);
      return mergedCart;
    }

    return newCart;
  }

  Cart _createNewCart(String sessionId, String deviceToken, {String? userId}) {
    return Cart(
      id: _generateCartId(),
      userId: userId ?? 'anonymous',
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sessionId: sessionId,
      deviceToken: deviceToken,
      isAnonymous: userId == null,
      sessionExpiresAt: DateTime.now().add(const Duration(minutes: 120)),
    );
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  String _generateDeviceToken() {
    return 'device_${Random().nextDouble().toString().substring(2, 18)}';
  }

  String _generateCartId() {
    return 'cart_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  @override
  void dispose() {
    _socketChannel?.sink.close();
    super.dispose();
  }
}