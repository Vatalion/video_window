import 'package:equatable/equatable.dart';

enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  dinersClub,
  jcb,
  unionPay,
  unknown,
}

enum CardValidationStatus {
  valid,
  invalidNumber,
  invalidExpiry,
  invalidCvv,
  expired,
  blocked,
}

class CardModel extends Equatable {
  final String id;
  final String userId;
  final CardBrand brand;
  final String lastFourDigits;
  final String expiryMonth;
  final String expiryYear;
  final String cardholderName;
  final bool isDefault;
  final bool isTokenized;
  final String? paymentToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsed;

  const CardModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
    required this.isDefault,
    required this.isTokenized,
    this.paymentToken,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsed,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      brand: CardBrand.values.firstWhere(
        (e) => e.name == json['brand'],
        orElse: () => CardBrand.unknown,
      ),
      lastFourDigits: json['last_four_digits'] as String,
      expiryMonth: json['expiry_month'] as String,
      expiryYear: json['expiry_year'] as String,
      cardholderName: json['cardholder_name'] as String,
      isDefault: json['is_default'] as bool,
      isTokenized: json['is_tokenized'] as bool,
      paymentToken: json['payment_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastUsed: json['last_used'] != null
          ? DateTime.parse(json['last_used'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'brand': brand.name,
      'last_four_digits': lastFourDigits,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cardholder_name': cardholderName,
      'is_default': isDefault,
      'is_tokenized': isTokenized,
      'payment_token': paymentToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_used': lastUsed?.toIso8601String(),
    };
  }

  CardModel copyWith({
    String? id,
    String? userId,
    CardBrand? brand,
    String? lastFourDigits,
    String? expiryMonth,
    String? expiryYear,
    String? cardholderName,
    bool? isDefault,
    bool? isTokenized,
    String? paymentToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsed,
  }) {
    return CardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardholderName: cardholderName ?? this.cardholderName,
      isDefault: isDefault ?? this.isDefault,
      isTokenized: isTokenized ?? this.isTokenized,
      paymentToken: paymentToken ?? this.paymentToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  bool get isExpired {
    final now = DateTime.now();
    final expiryDate = DateTime(
      int.parse(expiryYear),
      int.parse(expiryMonth) + 1,
      0,
    );
    return now.isAfter(expiryDate);
  }

  String get maskedNumber => '**** **** **** $lastFourDigits';

  @override
  List<Object?> get props => [
        id,
        userId,
        brand,
        lastFourDigits,
        expiryMonth,
        expiryYear,
        cardholderName,
        isDefault,
        isTokenized,
        paymentToken,
        createdAt,
        updatedAt,
        lastUsed,
      ];
}

class CardInputModel extends Equatable {
  final String cardNumber;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final String cardholderName;
  final bool saveCard;

  const CardInputModel({
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.cardholderName,
    required this.saveCard,
  });

  CardValidationStatus validate() {
    if (!_isValidCardNumber(cardNumber)) {
      return CardValidationStatus.invalidNumber;
    }

    if (!_isValidExpiry(expiryMonth, expiryYear)) {
      return CardValidationStatus.invalidExpiry;
    }

    if (!_isValidCvv(cvv)) {
      return CardValidationStatus.invalidCvv;
    }

    if (_isExpired(expiryMonth, expiryYear)) {
      return CardValidationStatus.expired;
    }

    return CardValidationStatus.valid;
  }

  bool _isValidCardNumber(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanNumber.length >= 13 && cleanNumber.length <= 19;
  }

  bool _isValidExpiry(String month, String year) {
    final monthInt = int.tryParse(month);
    final yearInt = int.tryParse(year);

    if (monthInt == null || yearInt == null) return false;
    if (monthInt < 1 || monthInt > 12) return false;

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (yearInt < currentYear) return false;
    if (yearInt == currentYear && monthInt < currentMonth) return false;

    return true;
  }

  bool _isValidCvv(String cvv) {
    final cleanCvv = cvv.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanCvv.length >= 3 && cleanCvv.length <= 4;
  }

  bool _isExpired(String month, String year) {
    final monthInt = int.tryParse(month) ?? 0;
    final yearInt = int.tryParse(year) ?? 0;

    if (monthInt == 0 || yearInt == 0) return false;

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (yearInt < currentYear) return true;
    if (yearInt == currentYear && monthInt < currentMonth) return true;

    return false;
  }

  @override
  List<Object> get props => [
        cardNumber,
        expiryMonth,
        expiryYear,
        cvv,
        cardholderName,
        saveCard,
      ];
}