import 'package:json_annotation/json_annotation.dart';
import 'cart_item.dart';

part 'cart.g.dart';

@JsonSerializable()
class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sessionId;
  final String? deviceToken;
  final bool isAnonymous;
  final DateTime? sessionExpiresAt;
  final Map<String, dynamic>? metadata;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    required this.sessionId,
    this.deviceToken,
    this.isAnonymous = false,
    this.sessionExpiresAt,
    this.metadata,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
  Map<String, dynamic> toJson() => _$CartToJson(this);

  Cart copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sessionId,
    String? deviceToken,
    bool? isAnonymous,
    DateTime? sessionExpiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionId: sessionId ?? this.sessionId,
      deviceToken: deviceToken ?? this.deviceToken,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      sessionExpiresAt: sessionExpiresAt ?? this.sessionExpiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Cart addItem(CartItem item) {
    final existingItemIndex = items.indexWhere((i) => i.id == item.id);
    List<CartItem> updatedItems;

    if (existingItemIndex >= 0) {
      updatedItems = List<CartItem>.from(items);
      updatedItems[existingItemIndex] = updatedItems[existingItemIndex].copyWith(
        quantity: updatedItems[existingItemIndex].quantity + item.quantity,
        updatedAt: DateTime.now(),
      );
    } else {
      updatedItems = [...items, item];
    }

    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  Cart removeItem(String itemId) {
    final updatedItems = items.where((item) => item.id != itemId).toList();
    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  Cart updateItemQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      return removeItem(itemId);
    }

    final updatedItems = items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          quantity: quantity,
          updatedAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  Cart clear() {
    return copyWith(
      items: [],
      updatedAt: DateTime.now(),
    );
  }
}