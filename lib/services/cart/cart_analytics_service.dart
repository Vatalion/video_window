import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';

class CartAnalyticsService {
  static const String _eventPrefix = 'cart_';

  void trackCartViewed(Cart cart) {
    _trackEvent('viewed', {
      'cart_id': cart.id,
      'user_id': cart.userId,
      'item_count': cart.items.length,
      'total_value': cart.subtotal,
      'is_anonymous': cart.isAnonymous,
      'session_id': cart.sessionId,
    });
  }

  void trackItemAdded(CartItem item, Cart cart) {
    _trackEvent('item_added', {
      'cart_id': cart.id,
      'item_id': item.id,
      'product_id': item.productId,
      'item_name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'total_value': item.totalPrice,
      'cart_total': cart.subtotal,
      'cart_item_count': cart.totalItems,
    });
  }

  void trackItemRemoved(CartItem item, Cart cart) {
    _trackEvent('item_removed', {
      'cart_id': cart.id,
      'item_id': item.id,
      'product_id': item.productId,
      'item_name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'total_value': item.totalPrice,
      'cart_total': cart.subtotal,
      'cart_item_count': cart.totalItems,
    });
  }

  void trackItemQuantityChanged(CartItem item, int oldQuantity, int newQuantity, Cart cart) {
    _trackEvent('item_quantity_changed', {
      'cart_id': cart.id,
      'item_id': item.id,
      'product_id': item.productId,
      'item_name': item.name,
      'price': item.price,
      'old_quantity': oldQuantity,
      'new_quantity': newQuantity,
      'quantity_change': newQuantity - oldQuantity,
      'cart_total': cart.subtotal,
      'cart_item_count': cart.totalItems,
    });
  }

  void trackCartCleared(Cart cart) {
    _trackEvent('cleared', {
      'cart_id': cart.id,
      'user_id': cart.userId,
      'item_count': cart.items.length,
      'total_value': cart.subtotal,
      'is_anonymous': cart.isAnonymous,
    });
  }

  void trackCartMerged(Cart localCart, Cart remoteCart, Cart mergedCart) {
    _trackEvent('merged', {
      'cart_id': mergedCart.id,
      'local_item_count': localCart.items.length,
      'remote_item_count': remoteCart.items.length,
      'merged_item_count': mergedCart.items.length,
      'local_total': localCart.subtotal,
      'remote_total': remoteCart.subtotal,
      'merged_total': mergedCart.subtotal,
      'merge_type': _determineMergeType(localCart, remoteCart),
    });
  }

  void trackCartSyncStarted(Cart cart) {
    _trackEvent('sync_started', {
      'cart_id': cart.id,
      'user_id': cart.userId,
      'item_count': cart.items.length,
      'total_value': cart.subtotal,
    });
  }

  void trackCartSyncCompleted(Cart cart, {bool success = true, String? error}) {
    _trackEvent('sync_completed', {
      'cart_id': cart.id,
      'user_id': cart.userId,
      'item_count': cart.items.length,
      'total_value': cart.subtotal,
      'success': success,
      'error': error,
    });
  }

  void trackCartSessionExpiry(Cart cart) {
    _trackEvent('session_expired', {
      'cart_id': cart.id,
      'user_id': cart.userId,
      'item_count': cart.items.length,
      'total_value': cart.subtotal,
      'is_anonymous': cart.isAnonymous,
      'session_duration': _calculateSessionDuration(cart),
    });
  }

  void trackCartAbandoned(Cart cart) {
    _trackEvent('abandoned', {
      'cart_id': cart.id,
      'user_id': cart.userId,
      'item_count': cart.items.length,
      'total_value': cart.subtotal,
      'is_anonymous': cart.isAnonymous,
      'time_since_last_update': _getTimeSinceLastUpdate(cart),
    });
  }

  void trackCartRestored(Cart cart, {String? restoredFrom}) {
    _trackEvent('restored', {
      'cart_id': cart.id,
      'user_id': cart.userId,
      'item_count': cart.items.length,
      'total_value': cart.subtotal,
      'restored_from': restoredFrom,
    });
  }

  void _trackEvent(String eventName, Map<String, dynamic> properties) {
    try {
      final fullEventName = '$_eventPrefix$eventName';
      final timestamp = DateTime.now().toIso8601String();

      final event = {
        'event': fullEventName,
        'timestamp': timestamp,
        'properties': {
          ...properties,
          'platform': 'flutter',
          'app_version': '1.0.0',
        },
      };

      // Send to analytics service (mock implementation)
      _sendToAnalyticsService(event);

      // Also log for debugging
      if (false) { // Set to true for debugging
        print('Analytics Event: $event');
      }
    } catch (e) {
      // Silently fail to avoid disrupting cart functionality
      print('Analytics tracking failed: $e');
    }
  }

  void _sendToAnalyticsService(Map<String, dynamic> event) {
    // In a real implementation, this would send to an analytics service
    // like Firebase Analytics, Amplitude, Mixpanel, etc.
    // For now, we'll just store in memory for demonstration

    // This would typically be:
    // FirebaseAnalytics().logEvent(name: event['event'], parameters: event['properties']);
    // or
    // Amplitude.track(event['event'], event: event);

    // Mock implementation - in production, replace with actual analytics service
    _mockAnalyticsStorage.add(event);
  }

  String _determineMergeType(Cart localCart, Cart remoteCart) {
    if (localCart.items.isEmpty && remoteCart.items.isNotEmpty) {
      return 'remote_only';
    } else if (remoteCart.items.isEmpty && localCart.items.isNotEmpty) {
      return 'local_only';
    } else if (localCart.items.length == remoteCart.items.length) {
      return 'conflict_resolution';
    } else {
      return 'combination';
    }
  }

  int _calculateSessionDuration(Cart cart) {
    return DateTime.now().difference(cart.createdAt).inSeconds;
  }

  int _getTimeSinceLastUpdate(Cart cart) {
    return DateTime.now().difference(cart.updatedAt).inSeconds;
  }

  // Mock storage for demonstration
  static final List<Map<String, dynamic>> _mockAnalyticsStorage = [];

  // For testing purposes
  static List<Map<String, dynamic>> getAnalyticsEvents() {
    return List<Map<String, dynamic>>.from(_mockAnalyticsStorage);
  }

  static void clearMockStorage() {
    _mockAnalyticsStorage.clear();
  }
}