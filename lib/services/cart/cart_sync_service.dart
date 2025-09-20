import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';

class CartSyncService {
  Cart mergeCarts(Cart localCart, Cart remoteCart) {
    final List<CartItem> mergedItems = [];

    final Map<String, CartItem> localItems = {
      for (final item in localCart.items) item.id: item,
    };

    final Map<String, CartItem> remoteItems = {
      for (final item in remoteCart.items) item.id: item,
    };

    final Set<String> allItemIds = {
      ...localItems.keys,
      ...remoteItems.keys,
    };

    for (final itemId in allItemIds) {
      final localItem = localItems[itemId];
      final remoteItem = remoteItems[itemId];

      if (localItem != null && remoteItem != null) {
        final mergedItem = _resolveItemConflict(localItem, remoteItem);
        mergedItems.add(mergedItem);
      } else if (localItem != null) {
        mergedItems.add(localItem);
      } else if (remoteItem != null) {
        mergedItems.add(remoteItem);
      }
    }

    return localCart.copyWith(
      items: mergedItems,
      updatedAt: DateTime.now(),
    );
  }

  CartItem _resolveItemConflict(CartItem localItem, CartItem remoteItem) {
    if (remoteItem.updatedAt.isAfter(localItem.updatedAt)) {
      return remoteItem.copyWith(
        quantity: localItem.quantity > remoteItem.quantity ? localItem.quantity : remoteItem.quantity,
      );
    } else {
      return localItem.copyWith(
        quantity: localItem.quantity > remoteItem.quantity ? localItem.quantity : remoteItem.quantity,
      );
    }
  }

  Future<Cart> resolveConflicts(Cart localCart, Cart remoteCart) async {
    final conflicts = _detectConflicts(localCart, remoteCart);

    if (conflicts.isEmpty) {
      return mergeCarts(localCart, remoteCart);
    }

    for (final conflict in conflicts) {
      final resolvedItem = await _resolveConflictUI(conflict);
      if (resolvedItem != null) {
        final index = localCart.items.indexWhere((item) => item.id == resolvedItem.id);
        if (index >= 0) {
          localCart.items[index] = resolvedItem;
        }
      }
    }

    return localCart.copyWith(
      updatedAt: DateTime.now(),
    );
  }

  List<_ConflictInfo> _detectConflicts(Cart localCart, Cart remoteCart) {
    final conflicts = <_ConflictInfo>[];

    final Map<String, CartItem> localItems = {
      for (final item in localCart.items) item.id: item,
    };

    final Map<String, CartItem> remoteItems = {
      for (final item in remoteCart.items) item.id: item,
    };

    for (final itemId in localItems.keys) {
      if (remoteItems.containsKey(itemId)) {
        final localItem = localItems[itemId]!;
        final remoteItem = remoteItems[itemId]!;

        if (localItem.updatedAt.difference(remoteItem.updatedAt).inMinutes < 5 &&
            (localItem.quantity != remoteItem.quantity ||
             localItem.price != remoteItem.price)) {
          conflicts.add(_ConflictInfo(
            itemId: itemId,
            localItem: localItem,
            remoteItem: remoteItem,
            conflictType: _ConflictType.quantityConflict,
          ));
        }
      }
    }

    return conflicts;
  }

  Future<CartItem?> _resolveConflictUI(_ConflictInfo conflict) async {
    return conflict.localItem;
  }

  void startSyncMonitoring(String userId) {
  }

  void stopSyncMonitoring() {
  }
}

class _ConflictInfo {
  final String itemId;
  final CartItem localItem;
  final CartItem remoteItem;
  final _ConflictType conflictType;

  _ConflictInfo({
    required this.itemId,
    required this.localItem,
    required this.remoteItem,
    required this.conflictType,
  });
}

enum _ConflictType {
  quantityConflict,
  priceConflict,
  variantConflict,
  availabilityConflict,
}