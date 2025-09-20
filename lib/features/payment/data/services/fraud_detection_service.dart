import 'dart:math';
import '../../domain/models/fraud_detection_model.dart';
import '../../domain/models/payment_model.dart';

class FraudDetectionService {
  static const Map<String, int> _velocityLimits = {
    'hourly': 10,
    'daily': 50,
    'weekly': 200,
  };

  static const Map<String, double> _amountLimits = {
    'hourly': 1000.0,
    'daily': 5000.0,
    'weekly': 20000.0,
  };

  Future<FraudDetectionModel> analyzePaymentRisk({
    required String userId,
    required String paymentId,
    required double amount,
    required String currency,
    String? ipAddress,
    String? deviceId,
    String? userAgent,
  }) async {
    final velocityData = await _getTransactionVelocity(userId);
    final riskScore = await _calculateRiskScore(
      userId: userId,
      amount: amount,
      currency: currency,
      velocityData: velocityData,
      ipAddress: ipAddress,
      deviceId: deviceId,
    );

    final failedChecks = await _performFraudChecks(
      userId: userId,
      amount: amount,
      velocityData: velocityData,
      ipAddress: ipAddress,
      deviceId: deviceId,
    );

    final riskLevel = _determineRiskLevel(riskScore);
    final riskFactors = _identifyRiskFactors(
      riskScore: riskScore,
      velocityData: velocityData,
      failedChecks: failedChecks,
    );

    return FraudDetectionModel(
      id: 'fraud_${DateTime.now().millisecondsSinceEpoch}',
      paymentId: paymentId,
      userId: userId,
      riskLevel: riskLevel,
      riskScore: riskScore,
      failedChecks: failedChecks,
      riskFactors: riskFactors,
      ipAddress: ipAddress,
      deviceId: deviceId,
      userAgent: userAgent,
      analysisData: {
        'velocity_data': velocityData.toJson(),
        'amount': amount,
        'currency': currency,
        'risk_score_breakdown': _getRiskScoreBreakdown(riskScore),
      },
      requiresManualReview: riskLevel == FraudRiskLevel.high || riskLevel == FraudRiskLevel.critical,
      createdAt: DateTime.now(),
    );
  }

  Future<TransactionVelocityData> _getTransactionVelocity(String userId) async {
    return TransactionVelocityData(
      userId: userId,
      ipAddress: '127.0.0.1',
      deviceId: 'device_123',
      transactionsLastHour: _random.nextInt(5),
      transactionsLast24Hours: _random.nextInt(20),
      transactionsLast7Days: _random.nextInt(100),
      totalAmountLastHour: _random.nextDouble() * 500,
      totalAmountLast24Hours: _random.nextDouble() * 2000,
      totalAmountLast7Days: _random.nextDouble() * 10000,
      lastTransactionTime: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      failedAttemptsLastHour: _random.nextInt(3),
    );
  }

  Future<double> _calculateRiskScore({
    required String userId,
    required double amount,
    required String currency,
    required TransactionVelocityData velocityData,
    String? ipAddress,
    String? deviceId,
  }) async {
    double riskScore = 0.0;

    riskScore += _calculateVelocityRisk(velocityData);
    riskScore += _calculateAmountRisk(amount, velocityData);
    riskScore += _calculateTimeRisk(velocityData.lastTransactionTime);
    riskScore += _calculateFailureRisk(velocityData.failedAttemptsLastHour);

    if (ipAddress != null && _isHighRiskIP(ipAddress)) {
      riskScore += 30;
    }

    if (deviceId != null && _isHighRiskDevice(deviceId)) {
      riskScore += 25;
    }

    riskScore += _calculateUserRisk(userId);

    return min(riskScore, 100.0);
  }

  double _calculateVelocityRisk(TransactionVelocityData velocityData) {
    double risk = 0.0;

    if (velocityData.transactionsLastHour > _velocityLimits['hourly']! * 0.8) {
      risk += 20;
    }
    if (velocityData.transactionsLast24Hours > _velocityLimits['daily']! * 0.8) {
      risk += 15;
    }
    if (velocityData.transactionsLast7Days > _velocityLimits['weekly']! * 0.8) {
      risk += 10;
    }

    return risk;
  }

  double _calculateAmountRisk(double amount, TransactionVelocityData velocityData) {
    double risk = 0.0;

    if (amount > 1000) risk += 10;
    if (amount > 5000) risk += 15;
    if (amount > 10000) risk += 20;

    if (velocityData.totalAmountLastHour > _amountLimits['hourly']! * 0.8) {
      risk += 25;
    }
    if (velocityData.totalAmountLast24Hours > _amountLimits['daily']! * 0.8) {
      risk += 20;
    }

    return risk;
  }

  double _calculateTimeRisk(DateTime lastTransactionTime) {
    final minutesSinceLastTransaction = DateTime.now().difference(lastTransactionTime).inMinutes;

    if (minutesSinceLastTransaction < 1) return 30;
    if (minutesSinceLastTransaction < 5) return 20;
    if (minutesSinceLastTransaction < 15) return 10;

    return 0.0;
  }

  double _calculateFailureRisk(int failedAttempts) {
    if (failedAttempts >= 5) return 40;
    if (failedAttempts >= 3) return 25;
    if (failedAttempts >= 1) return 10;

    return 0.0;
  }

  bool _isHighRiskIP(String ipAddress) {
    final highRiskRanges = [
      '192.168.',
      '10.',
      '172.16.',
    ];

    return highRiskRanges.any((range) => ipAddress.startsWith(range));
  }

  bool _isHighRiskDevice(String deviceId) {
    return deviceId.contains('emulator') || deviceId.contains('simulator');
  }

  double _calculateUserRisk(String userId) {
    return _random.nextDouble() * 10;
  }

  Future<List<FraudCheckType>> _performFraudChecks({
    required String userId,
    required double amount,
    required TransactionVelocityData velocityData,
    String? ipAddress,
    String? deviceId,
  }) async {
    final failedChecks = <FraudCheckType>[];

    if (velocityData.exceedsHourlyLimit) {
      failedChecks.add(FraudCheckType.velocityCheck);
    }

    if (velocityData.exceedsDailyLimit) {
      failedChecks.add(FraudCheckType.velocityCheck);
    }

    if (velocityData.hasUnusualActivity) {
      failedChecks.add(FraudCheckType.behaviorCheck);
    }

    if (ipAddress != null && _isHighRiskIP(ipAddress)) {
      failedChecks.add(FraudCheckType.ipRiskCheck);
    }

    if (deviceId != null && _isHighRiskDevice(deviceId)) {
      failedChecks.add(FraudCheckType.deviceRiskCheck);
    }

    return failedChecks;
  }

  FraudRiskLevel _determineRiskLevel(double riskScore) {
    if (riskScore >= 80) return FraudRiskLevel.critical;
    if (riskScore >= 60) return FraudRiskLevel.high;
    if (riskScore >= 40) return FraudRiskLevel.medium;
    return FraudRiskLevel.low;
  }

  List<String> _identifyRiskFactors({
    required double riskScore,
    required TransactionVelocityData velocityData,
    required List<FraudCheckType> failedChecks,
  }) {
    final factors = <String>[];

    if (riskScore > 70) factors.add('High overall risk score');
    if (failedChecks.contains(FraudCheckType.velocityCheck)) {
      factors.add('Unusual transaction velocity');
    }
    if (failedChecks.contains(FraudCheckType.ipRiskCheck)) {
      factors.add('Suspicious IP address');
    }
    if (failedChecks.contains(FraudCheckType.deviceRiskCheck)) {
      factors.add('Suspicious device');
    }
    if (failedChecks.contains(FraudCheckType.behaviorCheck)) {
      factors.add('Unusual behavior pattern');
    }

    return factors;
  }

  Map<String, dynamic> _getRiskScoreBreakdown(double riskScore) {
    return {
      'total_score': riskScore,
      'velocity_contribution': riskScore * 0.3,
      'amount_contribution': riskScore * 0.25,
      'time_contribution': riskScore * 0.2,
      'failure_contribution': riskScore * 0.15,
      'other_factors': riskScore * 0.1,
    };
  }

  Future<bool> blockPayment(String paymentId, String reason) async {
    return true;
  }

  Future<bool> unblockPayment(String paymentId) async {
    return true;
  }

  Future<List<Map<String, dynamic>>> getFraudAlerts() async {
    return [];
  }

  Future<bool> addPatternToBlacklist(Map<String, dynamic> pattern) async {
    return true;
  }

  Future<bool> removeFromBlacklist(String patternId) async {
    return true;
  }

  Future<Map<String, dynamic>> getFraudStatistics() async {
    return {
      'total_payments_analyzed': 0,
      'fraud_detected': 0,
      'false_positives': 0,
      'average_risk_score': 0.0,
      'blocked_payments': 0,
      'manual_reviews_required': 0,
    };
  }

  final Random _random = Random();
}