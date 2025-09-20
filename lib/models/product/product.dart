import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? salePrice;
  final List<ProductVariant> variants;
  final List<String> imageUrls;
  final List<ProductCategory> categories;
  final bool inStock;
  final int availableQuantity;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.variants,
    required this.imageUrls,
    required this.categories,
    required this.inStock,
    required this.availableQuantity,
    required this.rating,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  double get currentPrice => salePrice ?? price;
  bool get hasSale => salePrice != null && salePrice! < price;
  double get discountPercentage => hasSale ? ((price - salePrice!) / price * 100) : 0;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? salePrice,
    List<ProductVariant>? variants,
    List<String>? imageUrls,
    List<ProductCategory>? categories,
    bool? inStock,
    int? availableQuantity,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      variants: variants ?? this.variants,
      imageUrls: imageUrls ?? this.imageUrls,
      categories: categories ?? this.categories,
      inStock: inStock ?? this.inStock,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class ProductVariant {
  final String id;
  final String name;
  final String sku;
  final double price;
  final double? salePrice;
  final String? imageUrl;
  final Map<String, String> attributes;
  final bool inStock;
  final int availableQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductVariant({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    this.salePrice,
    this.imageUrl,
    required this.attributes,
    required this.inStock,
    required this.availableQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  double get currentPrice => salePrice ?? price;
  bool get hasSale => salePrice != null && salePrice! < price;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);
  Map<String, dynamic> toJson() => _$ProductVariantToJson(this);
}

@JsonSerializable()
class ProductCategory {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) => _$ProductCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCategoryToJson(this);
}

@JsonSerializable()
class ProductRecommendation {
  final String productId;
  final String recommendationType;
  final double score;
  final String reason;
  final DateTime createdAt;

  ProductRecommendation({
    required this.productId,
    required this.recommendationType,
    required this.score,
    required this.reason,
    required this.createdAt,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) => _$ProductRecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$ProductRecommendationToJson(this);
}