class Product {
  final String id;
  final String name;
  final String description;
  final ProductType type;
  final List<ProductMedia> media;
  final double price;
  final String currency;
  final int stockQuantity;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProductVariant>? variants;
  final ShippingInfo? shippingInfo;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.media,
    required this.price,
    required this.currency,
    required this.stockQuantity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.variants,
    this.shippingInfo,
  });

  Product copyWith({
    String? name,
    String? description,
    ProductType? type,
    List<ProductMedia>? media,
    double? price,
    String? currency,
    int? stockQuantity,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductVariant>? variants,
    ShippingInfo? shippingInfo,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      media: media ?? this.media,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      variants: variants ?? this.variants,
      shippingInfo: shippingInfo ?? this.shippingInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'media': media.map((m) => m.toJson()).toList(),
      'price': price,
      'currency': currency,
      'stockQuantity': stockQuantity,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'variants': variants?.map((v) => v.toJson()).toList(),
      'shippingInfo': shippingInfo?.toJson(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ProductType.fromString(json['type'] as String),
      media: (json['media'] as List)
          .map((m) => ProductMedia.fromJson(m as Map<String, dynamic>))
          .toList(),
      price: json['price'] as double,
      currency: json['currency'] as String,
      stockQuantity: json['stockQuantity'] as int,
      status: ProductStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      variants: (json['variants'] as List?)
          ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      shippingInfo: json['shippingInfo'] != null
          ? ShippingInfo.fromJson(json['shippingInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}

enum ProductType {
  physical,
  digital,
  service;

  static ProductType fromString(String type) {
    switch (type) {
      case 'ProductType.physical':
        return ProductType.physical;
      case 'ProductType.digital':
        return ProductType.digital;
      case 'ProductType.service':
        return ProductType.service;
      default:
        throw Exception('Unknown product type: $type');
    }
  }

  @override
  String toString() {
    switch (this) {
      case ProductType.physical:
        return 'ProductType.physical';
      case ProductType.digital:
        return 'ProductType.digital';
      case ProductType.service:
        return 'ProductType.service';
    }
  }
}

enum ProductStatus {
  draft,
  published,
  archived;

  static ProductStatus fromString(String status) {
    switch (status) {
      case 'ProductStatus.draft':
        return ProductStatus.draft;
      case 'ProductStatus.published':
        return ProductStatus.published;
      case 'ProductStatus.archived':
        return ProductStatus.archived;
      default:
        throw Exception('Unknown product status: $status');
    }
  }

  @override
  String toString() {
    switch (this) {
      case ProductStatus.draft:
        return 'ProductStatus.draft';
      case ProductStatus.published:
        return 'ProductStatus.published';
      case ProductStatus.archived:
        return 'ProductStatus.archived';
    }
  }
}

class ProductMedia {
  final String id;
  final String url;
  final MediaType type;
  final String altText;

  ProductMedia({
    required this.id,
    required this.url,
    required this.type,
    required this.altText,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type.toString(),
      'altText': altText,
    };
  }

  factory ProductMedia.fromJson(Map<String, dynamic> json) {
    return ProductMedia(
      id: json['id'] as String,
      url: json['url'] as String,
      type: MediaType.fromString(json['type'] as String),
      altText: json['altText'] as String,
    );
  }
}

enum MediaType {
  image,
  video;

  static MediaType fromString(String type) {
    switch (type) {
      case 'MediaType.image':
        return MediaType.image;
      case 'MediaType.video':
        return MediaType.video;
      default:
        throw Exception('Unknown media type: $type');
    }
  }

  @override
  String toString() {
    switch (this) {
      case MediaType.image:
        return 'MediaType.image';
      case MediaType.video:
        return 'MediaType.video';
    }
  }
}

class ProductVariant {
  final String id;
  final String name;
  final Map<String, String> options;
  final double price;
  final int stockQuantity;

  ProductVariant({
    required this.id,
    required this.name,
    required this.options,
    required this.price,
    required this.stockQuantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'options': options,
      'price': price,
      'stockQuantity': stockQuantity,
    };
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      options: Map<String, String>.from(json['options'] as Map),
      price: json['price'] as double,
      stockQuantity: json['stockQuantity'] as int,
    );
  }
}

class ShippingInfo {
  final double weight;
  final String dimensions;
  final bool requiresShipping;

  ShippingInfo({
    required this.weight,
    required this.dimensions,
    required this.requiresShipping,
  });

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'dimensions': dimensions,
      'requiresShipping': requiresShipping,
    };
  }

  factory ShippingInfo.fromJson(Map<String, dynamic> json) {
    return ShippingInfo(
      weight: json['weight'] as double,
      dimensions: json['dimensions'] as String,
      requiresShipping: json['requiresShipping'] as bool,
    );
  }
}