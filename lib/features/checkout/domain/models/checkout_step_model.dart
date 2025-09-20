import 'package:equatable/equatable.dart';

enum CheckoutStepType {
  cartReview,
  shippingAddress,
  billingAddress,
  paymentMethod,
  reviewOrder,
  confirmation,
}

class CheckoutStepModel extends Equatable {
  final CheckoutStepType type;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isRequired;
  final DateTime? completedAt;
  final Map<String, dynamic>? validationErrors;
  final int order;

  const CheckoutStepModel({
    required this.type,
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isActive = false,
    this.isRequired = true,
    this.completedAt,
    this.validationErrors,
    required this.order,
  });

  CheckoutStepModel copyWith({
    CheckoutStepType? type,
    String? title,
    String? subtitle,
    bool? isCompleted,
    bool? isActive,
    bool? isRequired,
    DateTime? completedAt,
    Map<String, dynamic>? validationErrors,
    int? order,
  }) {
    return CheckoutStepModel(
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      isRequired: isRequired ?? this.isRequired,
      completedAt: completedAt ?? this.completedAt,
      validationErrors: validationErrors ?? this.validationErrors,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
        type,
        title,
        subtitle,
        isCompleted,
        isActive,
        isRequired,
        completedAt,
        validationErrors,
        order,
      ];
}

class CheckoutStepDefinition {
  static List<CheckoutStepModel> getStandardSteps() {
    return [
      const CheckoutStepModel(
        type: CheckoutStepType.cartReview,
        title: 'Cart Review',
        subtitle: 'Review your items',
        order: 1,
      ),
      const CheckoutStepModel(
        type: CheckoutStepType.shippingAddress,
        title: 'Shipping Address',
        subtitle: 'Where should we deliver?',
        order: 2,
      ),
      const CheckoutStepModel(
        type: CheckoutStepType.billingAddress,
        title: 'Billing Address',
        subtitle: 'Billing information',
        order: 3,
        isRequired: false,
      ),
      const CheckoutStepModel(
        type: CheckoutStepType.paymentMethod,
        title: 'Payment Method',
        subtitle: 'Choose payment option',
        order: 4,
      ),
      const CheckoutStepModel(
        type: CheckoutStepType.reviewOrder,
        title: 'Review Order',
        subtitle: 'Confirm your order',
        order: 5,
      ),
      const CheckoutStepModel(
        type: CheckoutStepType.confirmation,
        title: 'Confirmation',
        subtitle: 'Order complete',
        order: 6,
      ),
    ];
  }
}