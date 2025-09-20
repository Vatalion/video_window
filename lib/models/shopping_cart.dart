import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'cart_item.dart';

part 'shopping_cart.g.dart';

@JsonSerializable()
class ShoppingCart extends Equatable {
  final String id;
  final String userId;
  final List<CartItem> items;
  final String sessionId;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String currency;
  final String? couponCode;
  final double? discountAmount;

  const ShoppingCart({
    required this.id,
    required this.userId,
    required this.items,
    required this.sessionId,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.currency,
    this.couponCode,
    this.discountAmount,
  });

  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  double get getSubtotal => items.fold<double>(0, (sum, item) => sum + item.totalPrice);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isExpiringSoon {
    final timeUntilExpiry = expiresAt.difference(DateTime.now());
    return timeUntilExpiry.inHours <= 24 && timeUntilExpiry.inHours > 0;
  }

  ShoppingCart copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    String? sessionId,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    double? subtotal,
    double? tax,
    double? shipping,
    double? total,
    String? currency,
    String? couponCode,
    double? discountAmount,
  }) {
    return ShoppingCart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      sessionId: sessionId ?? this.sessionId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      expiresAt: expiresAt ?? this.expiresAt,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shipping: shipping ?? this.shipping,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  ShoppingCart addItem(CartItem item) {
    final existingItemIndex = items.indexWhere(
      (cartItem) => cartItem.productId == item.productId &&
                   cartItem.variantId == item.variantId,
    );

    List<CartItem> updatedItems;
    if (existingItemIndex != -1) {
      final existingItem = items[existingItemIndex];
      updatedItems = List.from(items);
      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
    } else {
      updatedItems = [...items, item];
    }

  final newSubtotal = updatedItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final newTotal = newSubtotal + tax + shipping - (discountAmount ?? 0);

    return copyWith(
      items: updatedItems,
      subtotal: newSubtotal,
      total: newTotal,
    );
  }

  ShoppingCart removeItem(String itemId) {
    final updatedItems = items.where((item) => item.id != itemId).toList();
  final newSubtotal = updatedItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final newTotal = newSubtotal + tax + shipping - (discountAmount ?? 0);

    return copyWith(
      items: updatedItems,
      subtotal: newSubtotal,
      total: newTotal,
    );
  }

  ShoppingCart updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      return removeItem(itemId);
    }

    final updatedItems = items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

  final newSubtotal = updatedItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final newTotal = newSubtotal + tax + shipping - (discountAmount ?? 0);

    return copyWith(
      items: updatedItems,
      subtotal: newSubtotal,
      total: newTotal,
    );
  }

  ShoppingCart clear() {
    return copyWith(items: [], subtotal: 0, total: tax + shipping - (discountAmount ?? 0));
  }

  factory ShoppingCart.fromJson(Map<String, dynamic> json) => _$ShoppingCartFromJson(json);
  Map<String, dynamic> toJson() => _$ShoppingCartToJson(this);

  factory ShoppingCart.empty({
    required String userId,
    required String sessionId,
    bool isAnonymous = true,
    DateTime? expiresAt,
  }) {
    final expiry = expiresAt ?? (isAnonymous
        ? DateTime.now().add(const Duration(days: 7))
        : DateTime.now().add(const Duration(hours: 2)));

    return ShoppingCart(
      id: '',
      userId: userId,
      items: [],
      sessionId: sessionId,
      isAnonymous: isAnonymous,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expiresAt: expiry,
      subtotal: 0,
      tax: 0,
      shipping: 0,
      total: 0,
      currency: 'USD',
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        sessionId,
        isAnonymous,
        createdAt,
        updatedAt,
        expiresAt,
        subtotal,
        tax,
        shipping,
        total,
        currency,
        couponCode,
        discountAmount,
      ];
}