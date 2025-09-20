import 'package:equatable/equatable.dart';

enum FraudRiskLevel {
  low,
  medium,
  high,
  critical,
}

enum FraudCheckType {
  velocityCheck,
  locationCheck,
  behaviorCheck,
  cardRiskCheck,
  ipRiskCheck,
  deviceRiskCheck,
}

class FraudDetectionModel extends Equatable {
  final String id;
  final String paymentId;
  final String userId;
  final FraudRiskLevel riskLevel;
  final double riskScore;
  final List<FraudCheckType> failedChecks;
  final List<String> riskFactors;
  final String? ipAddress;
  final String? deviceId;
  final String? userAgent;
  final Map<String, dynamic> analysisData;
  final bool requiresManualReview;
  final DateTime createdAt;

  const FraudDetectionModel({
    required this.id,
    required this.paymentId,
    required this.userId,
    required this.riskLevel,
    required this.riskScore,
    required this.failedChecks,
    required this.riskFactors,
    this.ipAddress,
    this.deviceId,
    this.userAgent,
    required this.analysisData,
    required this.requiresManualReview,
    required this.createdAt,
  });

  factory FraudDetectionModel.fromJson(Map<String, dynamic> json) {
    return FraudDetectionModel(
      id: json['id'] as String,
      paymentId: json['payment_id'] as String,
      userId: json['user_id'] as String,
      riskLevel: FraudRiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => FraudRiskLevel.low,
      ),
      riskScore: (json['risk_score'] as num).toDouble(),
      failedChecks: (json['failed_checks'] as List)
          .map((check) => FraudCheckType.values.firstWhere(
                (e) => e.name == check,
                orElse: () => FraudCheckType.velocityCheck,
              ))
          .toList(),
      riskFactors: List<String>.from(json['risk_factors'] as List),
      ipAddress: json['ip_address'] as String?,
      deviceId: json['device_id'] as String?,
      userAgent: json['user_agent'] as String?,
      analysisData: Map<String, dynamic>.from(json['analysis_data'] as Map),
      requiresManualReview: json['requires_manual_review'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_id': paymentId,
      'user_id': userId,
      'risk_level': riskLevel.name,
      'risk_score': riskScore,
      'failed_checks': failedChecks.map((check) => check.name).toList(),
      'risk_factors': riskFactors,
      'ip_address': ipAddress,
      'device_id': deviceId,
      'user_agent': userAgent,
      'analysis_data': analysisData,
      'requires_manual_review': requiresManualReview,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isBlocked => riskLevel == FraudRiskLevel.critical;
  bool get isFlagged => riskLevel == FraudRiskLevel.high;
  bool get needsReview => requiresManualReview;

  @override
  List<Object?> get props => [
        id,
        paymentId,
        userId,
        riskLevel,
        riskScore,
        failedChecks,
        riskFactors,
        ipAddress,
        deviceId,
        userAgent,
        analysisData,
        requiresManualReview,
        createdAt,
      ];
}

class FraudCheckResult extends Equatable {
  final FraudCheckType checkType;
  final bool passed;
  final double score;
  final List<String> factors;
  final Map<String, dynamic> details;

  const FraudCheckResult({
    required this.checkType,
    required this.passed,
    required this.score,
    required this.factors,
    required this.details,
  });

  @override
  List<Object> get props => [checkType, passed, score, factors, details];
}

class TransactionVelocityData extends Equatable {
  final String userId;
  final String ipAddress;
  final String deviceId;
  final int transactionsLastHour;
  final int transactionsLast24Hours;
  final int transactionsLast7Days;
  final double totalAmountLastHour;
  final double totalAmountLast24Hours;
  final double totalAmountLast7Days;
  final DateTime lastTransactionTime;
  final int failedAttemptsLastHour;

  const TransactionVelocityData({
    required this.userId,
    required this.ipAddress,
    required this.deviceId,
    required this.transactionsLastHour,
    required this.transactionsLast24Hours,
    required this.transactionsLast7Days,
    required this.totalAmountLastHour,
    required this.totalAmountLast24Hours,
    required this.totalAmountLast7Days,
    required this.lastTransactionTime,
    required this.failedAttemptsLastHour,
  });

  factory TransactionVelocityData.fromJson(Map<String, dynamic> json) {
    return TransactionVelocityData(
      userId: json['user_id'] as String,
      ipAddress: json['ip_address'] as String,
      deviceId: json['device_id'] as String,
      transactionsLastHour: json['transactions_last_hour'] as int,
      transactionsLast24Hours: json['transactions_last_24_hours'] as int,
      transactionsLast7Days: json['transactions_last_7_days'] as int,
      totalAmountLastHour: (json['total_amount_last_hour'] as num).toDouble(),
      totalAmountLast24Hours: (json['total_amount_last_24_hours'] as num).toDouble(),
      totalAmountLast7Days: (json['total_amount_last_7_days'] as num).toDouble(),
      lastTransactionTime: DateTime.parse(json['last_transaction_time'] as String),
      failedAttemptsLastHour: json['failed_attempts_last_hour'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'ip_address': ipAddress,
      'device_id': deviceId,
      'transactions_last_hour': transactionsLastHour,
      'transactions_last_24_hours': transactionsLast24Hours,
      'transactions_last_7_days': transactionsLast7Days,
      'total_amount_last_hour': totalAmountLastHour,
      'total_amount_last_24_hours': totalAmountLast24Hours,
      'total_amount_last_7_days': totalAmountLast7Days,
      'last_transaction_time': lastTransactionTime.toIso8601String(),
      'failed_attempts_last_hour': failedAttemptsLastHour,
    };
  }

  bool get exceedsHourlyLimit => transactionsLastHour > 10;
  bool get exceedsDailyLimit => transactionsLast24Hours > 50;
  bool get exceedsWeeklyLimit => transactionsLast7Days > 200;
  bool get hasHighFailureRate => failedAttemptsLastHour > 5;
  bool get hasUnusualActivity => transactionsLastHour > 3 && failedAttemptsLastHour > 2;

  @override
  List<Object> get props => [
        userId,
        ipAddress,
        deviceId,
        transactionsLastHour,
        transactionsLast24Hours,
        transactionsLast7Days,
        totalAmountLastHour,
        totalAmountLast24Hours,
        totalAmountLast7Days,
        lastTransactionTime,
        failedAttemptsLastHour,
      ];
}