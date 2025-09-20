import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
  chargeback,
}

enum CardType {
  visa,
  mastercard,
  amex,
  discover,
  dinersClub,
  jcb,
  unionPay,
  unknown,
}

enum FraudRiskLevel {
  low,
  medium,
  high,
  critical,
}

class PaymentModel extends Equatable {
  final String id;
  final String userId;
  final String orderId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final CardType? cardType;
  final String? lastFourDigits;
  final String? transactionId;
  final String? errorMessage;
  final FraudRiskLevel riskLevel;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;

  const PaymentModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    this.cardType,
    this.lastFourDigits,
    this.transactionId,
    this.errorMessage,
    required this.riskLevel,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      cardType: json['card_type'] != null
          ? CardType.values.firstWhere(
              (e) => e.name == json['card_type'],
              orElse: () => CardType.unknown,
            )
          : null,
      lastFourDigits: json['last_four_digits'] as String?,
      transactionId: json['transaction_id'] as String?,
      errorMessage: json['error_message'] as String?,
      riskLevel: FraudRiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => FraudRiskLevel.low,
      ),
      isRecurring: json['is_recurring'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'card_type': cardType?.name,
      'last_four_digits': lastFourDigits,
      'transaction_id': transactionId,
      'error_message': errorMessage,
      'risk_level': riskLevel.name,
      'is_recurring': isRecurring,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? orderId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    CardType? cardType,
    String? lastFourDigits,
    String? transactionId,
    String? errorMessage,
    FraudRiskLevel? riskLevel,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? processedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      cardType: cardType ?? this.cardType,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      transactionId: transactionId ?? this.transactionId,
      errorMessage: errorMessage ?? this.errorMessage,
      riskLevel: riskLevel ?? this.riskLevel,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        orderId,
        amount,
        currency,
        status,
        cardType,
        lastFourDigits,
        transactionId,
        errorMessage,
        riskLevel,
        isRecurring,
        createdAt,
        updatedAt,
        processedAt,
      ];
}