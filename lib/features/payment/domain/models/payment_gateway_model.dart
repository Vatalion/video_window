import 'package:equatable/equatable.dart';

enum PaymentGatewayType {
  stripe,
  paypal,
  braintree,
  adyen,
  square,
  unknown,
}

enum PaymentGatewayStatus {
  active,
  inactive,
  maintenance,
  error,
}

class PaymentGatewayModel extends Equatable {
  final String id;
  final String name;
  final PaymentGatewayType type;
  final PaymentGatewayStatus status;
  final bool isDefault;
  final bool supportsRecurring;
  final bool supports3DSecure;
  final List<CardBrand> supportedCards;
  final double feePercentage;
  final double fixedFee;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentGatewayModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.isDefault,
    required this.supportsRecurring,
    required this.supports3DSecure,
    required this.supportedCards,
    required this.feePercentage,
    required this.fixedFee,
    required this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentGatewayModel.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PaymentGatewayType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentGatewayType.unknown,
      ),
      status: PaymentGatewayStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentGatewayStatus.inactive,
      ),
      isDefault: json['is_default'] as bool,
      supportsRecurring: json['supports_recurring'] as bool,
      supports3DSecure: json['supports_3d_secure'] as bool,
      supportedCards: (json['supported_cards'] as List)
          .map((card) => CardBrand.values.firstWhere(
                (e) => e.name == card,
                orElse: () => CardBrand.unknown,
              ))
          .toList(),
      feePercentage: (json['fee_percentage'] as num).toDouble(),
      fixedFee: (json['fixed_fee'] as num).toDouble(),
      config: Map<String, dynamic>.from(json['config'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'is_default': isDefault,
      'supports_recurring': supportsRecurring,
      'supports_3d_secure': supports3DSecure,
      'supported_cards': supportedCards.map((card) => card.name).toList(),
      'fee_percentage': feePercentage,
      'fixed_fee': fixedFee,
      'config': config,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool supportsCard(CardBrand brand) {
    return supportedCards.contains(brand);
  }

  double calculateFee(double amount) {
    return (amount * feePercentage / 100) + fixedFee;
  }

  @override
  List<Object> get props => [
        id,
        name,
        type,
        status,
        isDefault,
        supportsRecurring,
        supports3DSecure,
        supportedCards,
        feePercentage,
        fixedFee,
        config,
        createdAt,
        updatedAt,
      ];
}

class PaymentGatewayResponse extends Equatable {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? gatewayData;
  final DateTime processedAt;

  const PaymentGatewayResponse({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.errorCode,
    this.gatewayData,
    required this.processedAt,
  });

  factory PaymentGatewayResponse.success({
    required String transactionId,
    Map<String, dynamic>? gatewayData,
  }) {
    return PaymentGatewayResponse(
      success: true,
      transactionId: transactionId,
      gatewayData: gatewayData,
      processedAt: DateTime.now(),
    );
  }

  factory PaymentGatewayResponse.failure({
    required String errorMessage,
    String? errorCode,
    Map<String, dynamic>? gatewayData,
  }) {
    return PaymentGatewayResponse(
      success: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      gatewayData: gatewayData,
      processedAt: DateTime.now(),
    );
  }

  factory PaymentGatewayResponse.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayResponse(
      success: json['success'] as bool,
      transactionId: json['transaction_id'] as String?,
      errorMessage: json['error_message'] as String?,
      errorCode: json['error_code'] as String?,
      gatewayData: json['gateway_data'] as Map<String, dynamic>?,
      processedAt: DateTime.parse(json['processed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transaction_id': transactionId,
      'error_message': errorMessage,
      'error_code': errorCode,
      'gateway_data': gatewayData,
      'processed_at': processedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        success,
        transactionId,
        errorMessage,
        errorCode,
        gatewayData,
        processedAt,
      ];
}