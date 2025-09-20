import 'package:json_annotation/json_annotation.dart';

part 'cart_item.g.dart';

@JsonSerializable()
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String? imageUrl;
  final Map<String, dynamic>? variantAttributes;
  final DateTime addedAt;
  final DateTime updatedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.variantAttributes,
    required this.addedAt,
    required this.updatedAt,
  });

  double get totalPrice => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? imageUrl,
    Map<String, dynamic>? variantAttributes,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      variantAttributes: variantAttributes ?? this.variantAttributes,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}