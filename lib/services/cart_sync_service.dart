import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/shopping_cart.dart';
import '../models/cart_item.dart';

class CartSyncService {
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  final _cartController = StreamController<ShoppingCart>.broadcast();
  WebSocketChannel? _webSocketChannel;
  Timer? _syncTimer;
  Timer? _reconnectTimer;

  String _baseUrl = 'ws://localhost:8080/ws/cart';
  bool _isConnected = false;
  String? _currentUserId;

  Stream<ShoppingCart> get cartUpdates => _cartController.stream;

  Future<void> initialize() async {
    _startSyncTimer();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      _webSocketChannel = WebSocketChannel.connect(Uri.parse(_baseUrl));

      _webSocketChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          _logger.e('WebSocket error: $error');
          _handleWebSocketError();
        },
        onDone: () {
          _logger.i('WebSocket connection closed');
          _handleWebSocketError();
        },
      );

      _isConnected = true;
      _logger.i('WebSocket connected');
    } catch (e) {
      _logger.e('Failed to connect WebSocket: $e');
      _handleWebSocketError();
    }
  }

  void _handleWebSocketError() {
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _logger.i('Attempting to reconnect WebSocket...');
      _connectWebSocket();
    });
  }

  void _handleWebSocketMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      switch (type) {
        case 'cart_update':
          _handleCartUpdate(data);
          break;
        case 'sync_request':
          _handleSyncRequest(data);
          break;
        case 'conflict_detected':
          _handleConflictDetection(data);
          break;
        case 'pong':
          _logger.d('Received pong from server');
          break;
        default:
          _logger.w('Unknown message type: $type');
      }
    } catch (e) {
      _logger.e('Error handling WebSocket message: $e');
    }
  }

  void _handleCartUpdate(Map<String, dynamic> data) {
    try {
      final cartData = data['cart'];
      final cart = ShoppingCart.fromJson(cartData);

      // Check if this cart belongs to the current user
      if (_currentUserId != null && cart.userId == _currentUserId) {
        _cartController.add(cart);
        _logger.i('Received cart update for user: $_currentUserId');
      }
    } catch (e) {
      _logger.e('Error handling cart update: $e');
    }
  }

  void _handleSyncRequest(Map<String, dynamic> data) {
    // Handle sync requests from other devices
    final requestId = data['request_id'];
    final userId = data['user_id'];

    if (_currentUserId == userId) {
      // Send current cart state
      // This would typically involve getting the current cart and sending it back
      _logger.i('Handling sync request: $requestId');
    }
  }

  void _handleConflictDetection(Map<String, dynamic> data) {
    final conflictId = data['conflict_id'];
    final cartId = data['cart_id'];
    final serverVersion = data['server_version'];
    final clientVersion = data['client_version'];

    _logger.w('Conflict detected for cart $cartId: $conflictId');

    // Resolve conflict using "last writer wins" strategy
    // In a real implementation, this would involve user interaction
    _resolveConflict(conflictId, cartId, serverVersion, clientVersion);
  }

  void _resolveConflict(String conflictId, String cartId,
      Map<String, dynamic> serverVersion, Map<String, dynamic> clientVersion) {
    try {
      // Simple conflict resolution: server wins
      final serverCart = ShoppingCart.fromJson(serverVersion);
      _cartController.add(serverCart);

      _logger.i('Conflict resolved: server version selected for cart $cartId');

      // Send resolution confirmation
      _sendWebSocketMessage({
        'type': 'conflict_resolved',
        'conflict_id': conflictId,
        'resolution': 'server_wins',
      });
    } catch (e) {
      _logger.e('Error resolving conflict: $e');
    }
  }

  Future<void> syncCart(ShoppingCart cart) async {
    try {
      if (_isConnected) {
        final message = {
          'type': 'cart_sync',
          'cart': cart.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        };

        _sendWebSocketMessage(message);
        _logger.i('Cart sync sent: ${cart.id}');
      } else {
        // Queue sync for later
        _logger.w('WebSocket not connected, cart queued for sync');
      }
    } catch (e) {
      _logger.e('Error syncing cart: $e');
      throw Exception('Failed to sync cart: $e');
    }
  }

  void _sendWebSocketMessage(Map<String, dynamic> message) {
    if (_webSocketChannel != null && _isConnected) {
      try {
        final jsonString = jsonEncode(message);
        _webSocketChannel!.sink.add(jsonString);
      } catch (e) {
        _logger.e('Error sending WebSocket message: $e');
        _handleWebSocketError();
      }
    }
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        // Send ping to keep connection alive
        _sendWebSocketMessage({'type': 'ping'});
      }
    });
  }

  Future<void> setCurrentUser(String userId) async {
    _currentUserId = userId;

    // Reconnect WebSocket with new user context
    if (_isConnected) {
      _webSocketChannel?.sink.close();
      _isConnected = false;
    }

    _baseUrl = 'ws://localhost:8080/ws/cart?user_id=$userId';
    _connectWebSocket();

    _logger.i('Current user set: $userId');
  }

  Future<void> clearCurrentUser() async {
    _currentUserId = null;
    _webSocketChannel?.sink.close();
    _isConnected = false;
    _baseUrl = 'ws://localhost:8080/ws/cart';
    _logger.i('Current user cleared');
  }

  void _startOfflineSyncTimer() {
    // This would handle offline synchronization
    // syncing queued operations when connection is restored
  }

  Future<void> forceSync() async {
    try {
      if (_isConnected) {
        _sendWebSocketMessage({'type': 'force_sync'});
        _logger.i('Force sync requested');
      } else {
        _logger.w('Cannot force sync: WebSocket not connected');
      }
    } catch (e) {
      _logger.e('Error forcing sync: $e');
    }
  }

  bool get isConnected => _isConnected;

  Future<void> dispose() async {
    _syncTimer?.cancel();
    _reconnectTimer?.cancel();
    _webSocketChannel?.sink.close();
    await _cartController.close();
    _logger.i('Cart sync service disposed');
  }
}