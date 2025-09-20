import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_summary_model.g.dart';

@JsonSerializable()
class OrderItemModel extends Equatable {
  final String productId;
  final String productName;
  final String? productImage;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final Map<String, dynamic> variations;
  final Map<String, dynamic> metadata;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.variations = const {},
    this.metadata = const {},
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);

  OrderItemModel copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? unitPrice,
    int? quantity,
    double? subtotal,
    Map<String, dynamic>? variations,
    Map<String, dynamic>? metadata,
  }) {
    return OrderItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      variations: variations ?? this.variations,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        productImage,
        unitPrice,
        quantity,
        subtotal,
        variations,
        metadata,
      ];
}

@JsonSerializable()
class OrderSummaryModel extends Equatable {
  final List<OrderItemModel> items;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double discount;
  final double total;
  final String currency;
  final Map<String, dynamic> taxBreakdown;
  final Map<String, dynamic> shippingDetails;
  final Map<String, dynamic> discountDetails;
  final DateTime calculatedAt;
  final String calculationHash;

  const OrderSummaryModel({
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.tax,
    required this.discount,
    required this.total,
    required this.currency,
    this.taxBreakdown = const {},
    this.shippingDetails = const {},
    this.discountDetails = const {},
    required this.calculatedAt,
    required this.calculationHash,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$OrderSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSummaryModelToJson(this);

  OrderSummaryModel copyWith({
    List<OrderItemModel>? items,
    double? subtotal,
    double? shippingCost,
    double? tax,
    double? discount,
    double? total,
    String? currency,
    Map<String, dynamic>? taxBreakdown,
    Map<String, dynamic>? shippingDetails,
    Map<String, dynamic>? discountDetails,
    DateTime? calculatedAt,
    String? calculationHash,
  }) {
    return OrderSummaryModel(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingCost: shippingCost ?? this.shippingCost,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
      shippingDetails: shippingDetails ?? this.shippingDetails,
      discountDetails: discountDetails ?? this.discountDetails,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      calculationHash: calculationHash ?? this.calculationHash,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get hasItems => items.isNotEmpty;

  bool get hasDiscount => discount > 0;

  bool get hasTax => tax > 0;

  bool get hasShippingCost => shippingCost > 0;

  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedTax => '\$${tax.toStringAsFixed(2)}';
  String get formattedShipping => '\$${shippingCost.toStringAsFixed(2)}';
  String get formattedDiscount => '-\$${discount.toStringAsFixed(2)}';
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  List<ValidationRule> validate() {
    final rules = <ValidationRule>[];

    if (items.isEmpty) {
      rules.add(ValidationRule(
        field: 'items',
        message: 'Order must contain at least one item',
        type: ValidationType.required,
        severity: ValidationSeverity.error,
      ));
    }

    if (subtotal < 0) {
      rules.add(ValidationRule(
        field: 'subtotal',
        message: 'Subtotal cannot be negative',
        type: ValidationType.range,
        severity: ValidationSeverity.error,
      ));
    }

    if (shippingCost < 0) {
      rules.add(ValidationRule(
        field: 'shippingCost',
        message: 'Shipping cost cannot be negative',
        type: ValidationType.range,
        severity: ValidationSeverity.error,
      ));
    }

    if (tax < 0) {
      rules.add(ValidationRule(
        field: 'tax',
        message: 'Tax cannot be negative',
        type: ValidationType.range,
        severity: ValidationSeverity.error,
      ));
    }

    if (discount < 0) {
      rules.add(ValidationRule(
        field: 'discount',
        message: 'Discount cannot be negative',
        type: ValidationType.range,
        severity: ValidationSeverity.error,
      ));
    }

    if (total < 0) {
      rules.add(ValidationRule(
        field: 'total',
        message: 'Total cannot be negative',
        type: ValidationType.range,
        severity: ValidationSeverity.error,
      ));
    }

    // Validate calculation integrity
    final calculatedTotal = subtotal + shippingCost + tax - discount;
    if ((calculatedTotal - total).abs() > 0.01) {
      rules.add(ValidationRule(
        field: 'total',
        message: 'Order total calculation mismatch detected',
        type: ValidationType.security,
        severity: ValidationSeverity.critical,
        expectedValue: calculatedTotal,
        actualValue: total,
      ));
    }

    return rules;
  }

  @override
  List<Object?> get props => [
        items,
        subtotal,
        shippingCost,
        tax,
        discount,
        total,
        currency,
        taxBreakdown,
        shippingDetails,
        discountDetails,
        calculatedAt,
        calculationHash,
      ];
}

@JsonSerializable()
class OrderCalculationRequest extends Equatable {
  final List<OrderItemModel> items;
  final String shippingAddressId;
  final String? couponCode;
  final String currency;

  const OrderCalculationRequest({
    required this.items,
    required this.shippingAddressId,
    this.couponCode,
    required this.currency,
  });

  factory OrderCalculationRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderCalculationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCalculationRequestToJson(this);

  @override
  List<Object?> get props => [
        items,
        shippingAddressId,
        couponCode,
        currency,
      ];
}