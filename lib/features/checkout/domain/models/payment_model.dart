import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

enum PaymentMethodType {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  bankTransfer,
  cashOnDelivery,
}

enum CardType {
  visa,
  mastercard,
  americanExpress,
  discover,
  unionPay,
  jcb,
  dinersClub,
  maestro,
  unknown,
}

@JsonSerializable()
class PaymentMethodModel extends Equatable {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final CardType? cardType;
  final String? lastFourDigits;
  final String? cardholderName;
  final int? expiryMonth;
  final int? expiryYear;
  final String? cardToken;
  final String? billingAddressId;
  final bool isDefault;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    this.cardType,
    this.lastFourDigits,
    this.cardholderName,
    this.expiryMonth,
    this.expiryYear,
    this.cardToken,
    this.billingAddressId,
    this.isDefault = false,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentMethodModelToJson(this);

  PaymentMethodModel copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    CardType? cardType,
    String? lastFourDigits,
    String? cardholderName,
    int? expiryMonth,
    int? expiryYear,
    String? cardToken,
    String? billingAddressId,
    bool? isDefault,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      cardType: cardType ?? this.cardType,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      cardholderName: cardholderName ?? this.cardholderName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardToken: cardToken ?? this.cardToken,
      billingAddressId: billingAddressId ?? this.billingAddressId,
      isDefault: isDefault ?? this.isDefault,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get displayText {
    switch (type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return '${cardType?.name.toUpperCase() ?? 'Card'} ending in $lastFourDigits';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.googlePay:
        return 'Google Pay';
      case PaymentMethodType.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethodType.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }

  bool get isExpired {
    if (expiryMonth == null || expiryYear == null) return false;

    final now = DateTime.now();
    final expiryDate = DateTime(expiryYear!, expiryMonth!);
    return now.isAfter(expiryDate);
  }

  static CardType detectCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.startsWith('4')) {
      return CardType.visa;
    } else if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return CardType.mastercard;
    } else if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return CardType.americanExpress;
    } else if (cleanNumber.startsWith('65')) {
      return CardType.discover;
    } else if (cleanNumber.startsWith('62')) {
      return CardType.unionPay;
    } else if (cleanNumber.startsWith('35')) {
      return CardType.jcb;
    } else if (cleanNumber.startsWith('36') || cleanNumber.startsWith('38')) {
      return CardType.dinersClub;
    } else if (cleanNumber.startsWith('50') || cleanNumber.startsWith('56') ||
               cleanNumber.startsWith('57') || cleanNumber.startsWith('58') ||
               cleanNumber.startsWith('6')) {
      return CardType.maestro;
    }

    return CardType.unknown;
  }

  List<ValidationRule> validate() {
    final rules = <ValidationRule>[];

    if (type == PaymentMethodType.creditCard || type == PaymentMethodType.debitCard) {
      if (cardholderName == null || cardholderName!.trim().isEmpty) {
        rules.add(ValidationRule(
          field: 'cardholderName',
          message: 'Cardholder name is required',
          type: ValidationType.required,
          severity: ValidationSeverity.error,
        ));
      }

      if (expiryMonth == null || expiryYear == null) {
        rules.add(ValidationRule(
          field: 'expiry',
          message: 'Expiry date is required',
          type: ValidationType.required,
          severity: ValidationSeverity.error,
        ));
      } else if (isExpired) {
        rules.add(ValidationRule(
          field: 'expiry',
          message: 'Card has expired',
          type: ValidationType.custom,
          severity: ValidationSeverity.error,
        ));
      }

      if (lastFourDigits == null || lastFourDigits!.length != 4) {
        rules.add(ValidationRule(
          field: 'lastFourDigits',
          message: 'Invalid card number format',
          type: ValidationType.format,
          severity: ValidationSeverity.error,
        ));
      }
    }

    // PCI compliance checks
    if (cardholderName?.toLowerCase().contains('test') ?? false) {
      rules.add(ValidationRule(
        field: 'cardholderName',
        message: 'Test cardholder names are not allowed for real transactions',
        type: ValidationType.pci,
        severity: ValidationSeverity.error,
      ));
    }

    if (cardToken == null || cardToken!.isEmpty) {
      rules.add(ValidationRule(
        field: 'cardToken',
        message: 'Payment token is required',
        type: ValidationType.security,
        severity: ValidationSeverity.critical,
      ));
    }

    return rules;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        cardType,
        lastFourDigits,
        cardholderName,
        expiryMonth,
        expiryYear,
        cardToken,
        billingAddressId,
        isDefault,
        isVerified,
        createdAt,
        updatedAt,
      ];
}

@JsonSerializable()
class PaymentTransactionModel extends Equatable {
  final String id;
  final String sessionId;
  final String paymentMethodId;
  final double amount;
  final String currency;
  final String transactionId;
  final PaymentStatus status;
  final String? authorizationCode;
  final String? errorCode;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? processedAt;
  final Map<String, dynamic> metadata;

  const PaymentTransactionModel({
    required this.id,
    required this.sessionId,
    required this.paymentMethodId,
    required this.amount,
    required this.currency,
    required this.transactionId,
    required this.status,
    this.authorizationCode,
    this.errorCode,
    this.errorMessage,
    required this.createdAt,
    this.processedAt,
    this.metadata = const {},
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentTransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentTransactionModelToJson(this);

  PaymentTransactionModel copyWith({
    String? id,
    String? sessionId,
    String? paymentMethodId,
    double? amount,
    String? currency,
    String? transactionId,
    PaymentStatus? status,
    String? authorizationCode,
    String? errorCode,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? processedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransactionModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      authorizationCode: authorizationCode ?? this.authorizationCode,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        paymentMethodId,
        amount,
        currency,
        transactionId,
        status,
        authorizationCode,
        errorCode,
        errorMessage,
        createdAt,
        processedAt,
        metadata,
      ];
}

enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}