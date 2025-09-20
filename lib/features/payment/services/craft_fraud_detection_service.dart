import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';

/// Craft-specific fraud detection service with pattern recognition
/// for custom orders, seasonal fluctuations, and material costs
class CraftFraudDetectionService {
  final Map<String, CraftFraudPattern> _fraudPatterns = {};
  final Map<String, TransactionHistory> _userHistories = {};
  final Map<String, MaterialPriceData> _materialPrices = {};
  final Random _random = Random();

  CraftFraudDetectionService() {
    _initializeFraudPatterns();
    _initializeMaterialPrices();
  }

  /// Analyze payment risk with craft-specific patterns
  Future<FraudAnalysisResult> analyzePaymentRisk({
    required String userId,
    required String paymentId,
    required double amount,
    required String currency,
    required Map<String, dynamic> transactionData,
    required Map<String, dynamic> userData,
    String? ipAddress,
    String? deviceId,
    String? userAgent,
  }) async {
    try {
      final analysisChecks = <FraudAnalysisCheck>[];

      // 1. Craft-specific price analysis
      final priceAnalysis = await _analyzeCraftPrice(
        amount: amount,
        currency: currency,
        transactionData: transactionData,
      );
      analysisChecks.add(priceAnalysis);

      // 2. Custom order pattern analysis
      final customOrderAnalysis = await _analyzeCustomOrderPattern(
        userId: userId,
        transactionData: transactionData,
        userData: userData,
      );
      analysisChecks.add(customOrderAnalysis);

      // 3. Seasonal fluctuation analysis
      final seasonalAnalysis = await _analyzeSeasonalPattern(
        amount: amount,
        transactionData: transactionData,
      );
      analysisChecks.add(seasonalAnalysis);

      // 4. Material cost analysis
      final materialAnalysis = await _analyzeMaterialCosts(
        amount: amount,
        transactionData: transactionData,
      );
      analysisChecks.add(materialAnalysis);

      // 5. Creator reputation analysis
      final reputationAnalysis = await _analyzeCreatorReputation(
        userId: userId,
        transactionData: transactionData,
      );
      analysisChecks.add(reputationAnalysis);

      // 6. Transaction velocity (craft-specific)
      final velocityAnalysis = await _analyzeCraftTransactionVelocity(
        userId: userId,
        amount: amount,
        ipAddress: ipAddress,
        deviceId: deviceId,
      );
      analysisChecks.add(velocityAnalysis);

      // 7. High-value item analysis
      final highValueAnalysis = await _analyzeHighValueItems(
        amount: amount,
        transactionData: transactionData,
      );
      analysisChecks.add(highValueAnalysis);

      // 8. Rush order analysis
      final rushOrderAnalysis = await _analyzeRushOrder(
        transactionData: transactionData,
      );
      analysisChecks.add(rushOrderAnalysis);

      // Calculate overall risk score
      final overallRiskScore = _calculateOverallRiskScore(analysisChecks);

      // Determine risk level and required action
      final riskLevel = _determineRiskLevel(overallRiskScore);
      final requiredAction = _determineRequiredAction(riskLevel, analysisChecks);

      // Generate risk factors
      final riskFactors = _generateRiskFactors(analysisChecks);

      final result = FraudAnalysisResult(
        overallRiskScore: overallRiskScore,
        riskLevel: riskLevel,
        requiredAction: requiredAction,
        analysisChecks: analysisChecks,
        riskFactors: riskFactors,
        requiresManualReview: riskLevel == FraudRiskLevel.high || riskLevel == FraudRiskLevel.critical,
        craftSpecificInsights: _generateCraftSpecificInsights(analysisChecks),
        timestamp: DateTime.now(),
      );

      // Update user history
      await _updateUserHistory(userId, result);

      return result;
    } catch (e) {
      return FraudAnalysisResult(
        overallRiskScore: 0.8, // High risk due to error
        riskLevel: FraudRiskLevel.high,
        requiredAction: FraudAction.manualReview,
        analysisChecks: [],
        riskFactors: ['system_error'],
        requiresManualReview: true,
        craftSpecificInsights: ['Fraud analysis system error: $e'],
        timestamp: DateTime.now(),
      );
    }
  }

  /// Analyze craft-specific pricing patterns
  Future<FraudAnalysisCheck> _analyzeCraftPrice({
    required double amount,
    required String currency,
    required Map<String, dynamic> transactionData,
  }) async {
    final items = transactionData['items'] as List<dynamic>? ?? [];
    final totalPrice = items.fold<double>(0, (sum, item) => sum + (item['price'] as num).toDouble());

    // Check for suspicious pricing patterns
    final pricingIssues = <String>[];

    // Round numbers are suspicious in craft (should have specific material costs)
    if (amount % 1 == 0 && amount > 50) {
      pricingIssues.add('round_number_pricing');
    }

    // Check if total price matches expected craft pricing
    if (items.isNotEmpty) {
      final expectedPriceRange = _calculateExpectedCraftPrice(items);
      if (amount < expectedPriceRange.min || amount > expectedPriceRange.max) {
        pricingIssues.add('price_outside_expected_range');
      }
    }

    // Check for unusually high or low per-item prices
    for (final item in items) {
      final itemPrice = (item['price'] as num).toDouble();
      final itemType = item['type'] as String? ?? 'unknown';

      if (itemPrice > 1000) {
        pricingIssues.add('extremely_high_item_price');
      }

      if (itemPrice < 5 && itemType != 'accessory') {
        pricingIssues.add('suspiciously_low_item_price');
      }
    }

    final riskScore = _calculatePricingRiskScore(pricingIssues);

    return FraudAnalysisCheck(
      checkType: FraudCheckType.craftPricing,
      riskScore: riskScore,
      passed: riskScore < 0.7,
      details: {
        'amount': amount,
        'currency': currency,
        'item_count': items.length,
        'pricing_issues': pricingIssues,
        'expected_range': _calculateExpectedCraftPrice(items),
      },
    );
  }

  /// Analyze custom order patterns
  Future<FraudAnalysisCheck> _analyzeCustomOrderPattern({
    required String userId,
    required Map<String, dynamic> transactionData,
    required Map<String, dynamic> userData,
  }) async {
    final isCustomOrder = transactionData['is_custom_order'] as bool? ?? false;
    final customizations = transactionData['customizations'] as List<dynamic>? ?? [];

    final riskFactors = <String>[];

    if (isCustomOrder) {
      // Check for suspicious custom order patterns
      if (customizations.isEmpty) {
        riskFactors.add('custom_order_no_customizations');
      }

      // Check for extremely complex customizations
      if (customizations.length > 10) {
        riskFactors.add('excessive_customizations');
      }

      // Check for unrealistic delivery expectations
      final deliveryDays = transactionData['delivery_days'] as int? ?? 0;
      if (deliveryDays < 3 && customizations.isNotEmpty) {
        riskFactors.add('unrealistic_custom_delivery');
      }

      // Check user's custom order history
      final userHistory = _userHistories[userId];
      if (userHistory != null) {
        final recentCustomOrders = userHistory.customOrders.where(
          (order) => DateTime.now().difference(order.timestamp).inDays < 30,
        ).length;

        if (recentCustomOrders > 5) {
          riskFactors.add('high_frequency_custom_orders');
        }
      }
    }

    final riskScore = _calculateCustomizationRiskScore(riskFactors);

    return FraudAnalysisCheck(
      checkType: FraudCheckType.customOrder,
      riskScore: riskScore,
      passed: riskScore < 0.6,
      details: {
        'is_custom_order': isCustomOrder,
        'customization_count': customizations.length,
        'risk_factors': riskFactors,
      },
    );
  }

  /// Analyze seasonal fluctuation patterns
  Future<FraudAnalysisCheck> _analyzeSeasonalPattern({
    required double amount,
    required Map<String, dynamic> transactionData,
  }) async {
    final now = DateTime.now();
    final isPeakSeason = _isPeakSeason(now);
    final isHolidaySeason = _isHolidaySeason(now);

    final seasonalRiskFactors = <String>[];

    // Check for suspicious seasonal pricing
    final seasonalMultiplier = _getSeasonalMultiplier(now);
    final basePrice = amount / seasonalMultiplier;

    if (isPeakSeason && basePrice > 500) {
      seasonalRiskFactors.add('high_value_peak_season');
    }

    // Check for unusual holiday patterns
    if (isHolidaySeason && amount > 1000) {
      seasonalRiskFactors.add('high_value_holiday_purchase');
    }

    // Check for off-season large purchases
    if (!isPeakSeason && amount > 800) {
      seasonalRiskFactors.add('high_value_off_season');
    }

    final riskScore = _calculateSeasonalRiskScore(seasonalRiskFactors, seasonalMultiplier);

    return FraudAnalysisCheck(
      checkType: FraudCheckType.seasonalPattern,
      riskScore: riskScore,
      passed: riskScore < 0.5,
      details: {
        'seasonal_multiplier': seasonalMultiplier,
        'is_peak_season': isPeakSeason,
        'is_holiday_season': isHolidaySeason,
        'base_price': basePrice,
        'seasonal_factors': seasonalRiskFactors,
      },
    );
  }

  /// Analyze material costs
  Future<FraudAnalysisCheck> _analyzeMaterialCosts({
    required double amount,
    required Map<String, dynamic> transactionData,
  }) async {
    final items = transactionData['items'] as List<dynamic>? ?? [];
    final materialCostIssues = <String>[];

    for (final item in items) {
      final materials = item['materials'] as List<dynamic>? ?? [];
      final itemPrice = (item['price'] as num).toDouble();

      // Calculate expected material costs
      double totalMaterialCost = 0;
      for (final material in materials) {
        final materialType = material['type'] as String;
        final quantity = (material['quantity'] as num).toDouble();

        final baseCost = _getMaterialBaseCost(materialType);
        totalMaterialCost += baseCost * quantity;
      }

      // Check if price is reasonable for materials
      final reasonableMultiplier = _getReasonablePriceMultiplier(materials.length);
      final reasonablePrice = totalMaterialCost * reasonableMultiplier;

      if (itemPrice < totalMaterialCost * 0.8) {
        materialCostIssues.add('price_below_material_cost');
      }

      if (itemPrice > reasonablePrice * 1.5) {
        materialCostIssues.add('price_excessive_for_materials');
      }

      // Check for suspicious material combinations
      if (_hasSuspiciousMaterialCombination(materials)) {
        materialCostIssues.add('suspicious_material_combination');
      }
    }

    final riskScore = _calculateMaterialRiskScore(materialCostIssues);

    return FraudAnalysisCheck(
      checkType: FraudCheckType.materialCost,
      riskScore: riskScore,
      passed: riskScore < 0.7,
      details: {
        'material_cost_issues': materialCostIssues,
        'total_items': items.length,
      },
    );
  }

  /// Analyze creator reputation
  Future<FraudAnalysisCheck> _analyzeCreatorReputation({
    required String userId,
    required Map<String, dynamic> transactionData,
  }) async {
    final creatorId = transactionData['creator_id'] as String?;
    final reputationIssues = <String>[];

    if (creatorId != null) {
      // Check creator's reputation score
      final reputationScore = await _getCreatorReputationScore(creatorId);

      if (reputationScore < 0.3) {
        reputationIssues.add('low_creator_reputation');
      }

      // Check for recent complaints
      final recentComplaints = await _getRecentComplaints(creatorId);
      if (recentComplaints > 3) {
        reputationIssues.add('high_complaint_rate');
      }

      // Check account age
      final accountAge = await _getCreatorAccountAge(creatorId);
      if (accountAge.inDays < 30) {
        reputationIssues.add('new_creator_account');
      }
    } else {
      reputationIssues.add('missing_creator_information');
    }

    final riskScore = _calculateReputationRiskScore(reputationIssues);

    return FraudAnalysisCheck(
      checkType: FraudCheckType.creatorReputation,
      riskScore: riskScore,
      passed: riskScore < 0.6,
      details: {
        'creator_id': creatorId,
        'reputation_issues': reputationIssues,
      },
    );
  }

  /// Analyze craft-specific transaction velocity
  Future<FraudAnalysisCheck> _analyzeCraftTransactionVelocity({
    required String userId,
    required double amount,
    String? ipAddress,
    String? deviceId,
  }) async {
    final userHistory = _userHistories[userId];
    final velocityIssues = <String>[];

    if (userHistory != null) {
      final now = DateTime.now();

      // Check recent transaction count (craft-specific: lower threshold)
      final recentTransactions = userHistory.transactions.where(
        (tx) => now.difference(tx.timestamp).inHours < 24,
      ).length;

      if (recentTransactions > 3) {
        velocityIssues.add('high_craft_transaction_frequency');
      }

      // Check recent total amount (craft-specific: lower threshold)
      final recentTotal = userHistory.transactions
          .where((tx) => now.difference(tx.timestamp).inHours < 24)
          .fold<double>(0, (sum, tx) => sum + tx.amount);

      if (recentTotal > 500) {
        velocityIssues.add('high_craft_daily_total');
      }

      // Check for rapid fire transactions
      final veryRecentTransactions = userHistory.transactions.where(
        (tx) => now.difference(tx.timestamp).inMinutes < 30,
      ).length;

      if (veryRecentTransactions > 2) {
        velocityIssues.add('rapid_craft_transactions');
      }
    }

    final riskScore = _calculateVelocityRiskScore(velocityIssues);

    return FraudAnalysisCheck(
      checkType: FraudCheckType.transactionVelocity,
      riskScore: riskScore,
      passed: riskScore < 0.6,
      details: {
        'velocity_issues': velocityIssues,
        'user_history_available': userHistory != null,
      },
    );
  }

  /// Analyze high-value items
  Future<FraudAnalysisCheck> _analyzeHighValueItems({
    required double amount,
    required Map<String, dynamic> transactionData,
  }) async {
    final items = transactionData['items'] as List<dynamic>? ?? [];
    final highValueIssues = <String>[];

    for (final item in items) {
      final itemPrice = (item['price'] as num).toDouble();
      final itemType = item['type'] as String? ?? 'unknown';

      // Craft-specific high value thresholds
      if (itemType.contains('jewelry') && itemPrice > 2000) {
        highValueIssues.add('high_value_jewelry');
      }

      if (itemType.contains('furniture') && itemPrice > 1500) {
        highValueIssues.add('high_value_furniture');
      }

      if (itemType.contains('art') && itemPrice > 3000) {
        highValueIssues.add('high_value_art');
      }

      // Check for new customer high-value purchases
      if (itemPrice > 1000 && transactionData['is_first_purchase'] as bool? ?? false) {
        highValueIssues.add('first_purchase_high_value');
      }
    }

    final riskScore = _calculateHighValueRiskScore(highValueIssues, amount);

    return FraudAnalysisCheck(
      checkType: FraudCheckType.highValueItem,
      riskScore: riskScore,
      passed: riskScore < 0.7,
      details: {
        'high_value_issues': highValueIssues,
        'total_amount': amount,
      },
    );
  }

  /// Analyze rush order patterns
  Future<FraudAnalysisCheck> _analyzeRushOrder({
    required Map<String, dynamic> transactionData,
  }) async {
    final isRushOrder = transactionData['is_rush_order'] as bool? ?? false;
    final rushOrderIssues = <String>[];

    if (isRushOrder) {
      final rushFee = transactionData['rush_fee'] as double? ?? 0;
      final deliveryDays = transactionData['delivery_days'] as int? ?? 0;

      // Check for excessive rush fees
      if (rushFee > 100) {
        rushOrderIssues.add('excessive_rush_fee');
      }

      // Check for impossible delivery times
      if (deliveryDays < 1) {
        rushOrderIssues.add('impossible_delivery_time');
      }

      // Check for rush order on high-value items
      final totalAmount = transactionData['amount'] as double? ?? 0;
      if (totalAmount > 1000 && deliveryDays < 3) {
        rushOrderIssues.add('high_value_rush_order');
      }
    }

    final riskScore = _calculateRushOrderRiskScore(rushOrderIssues);

    return FraudAnalysisCheck(
      checkType: FraudCheckType.rushOrder,
      riskScore: riskScore,
      passed: riskScore < 0.5,
      details: {
        'is_rush_order': isRushOrder,
        'rush_order_issues': rushOrderIssues,
      },
    );
  }

  // Helper methods for risk calculation and data initialization

  void _initializeFraudPatterns() {
    _fraudPatterns.addAll({
      'round_number_pricing': CraftFraudPattern(
        name: 'Round Number Pricing',
        description: 'Suspicious round number pricing in craft items',
        baseRiskScore: 0.4,
      ),
      'price_outside_expected_range': CraftFraudPattern(
        name: 'Price Outside Expected Range',
        description: 'Craft item price outside expected range',
        baseRiskScore: 0.6,
      ),
      'suspicious_material_combination': CraftFraudPattern(
        name: 'Suspicious Material Combination',
        description: 'Unusual material combination for craft type',
        baseRiskScore: 0.5,
      ),
    });
  }

  void _initializeMaterialPrices() {
    _materialPrices.addAll({
      'gold': MaterialPriceData(baseCost: 60.0, volatility: 0.1),
      'silver': MaterialPriceData(baseCost: 0.8, volatility: 0.05),
      'wood': MaterialPriceData(baseCost: 2.5, volatility: 0.15),
      'fabric': MaterialPriceData(baseCost: 8.0, volatility: 0.2),
      'leather': MaterialPriceData(baseCost: 15.0, volatility: 0.1),
      'gemstone': MaterialPriceData(baseCost: 25.0, volatility: 0.3),
    });
  }

  PriceRange _calculateExpectedCraftPrice(List<dynamic> items) {
    // Implementation for calculating expected craft price range
    return PriceRange(min: 25.0, max: 500.0);
  }

  double _calculatePricingRiskScore(List<String> issues) {
    return min(0.9, issues.length * 0.2);
  }

  double _calculateCustomizationRiskScore(List<String> factors) {
    return min(0.8, factors.length * 0.15);
  }

  double _calculateSeasonalRiskScore(List<String> factors, double multiplier) {
    return min(0.7, factors.length * 0.1 + (1.0 - multiplier) * 0.3);
  }

  double _calculateMaterialRiskScore(List<String> issues) {
    return min(0.8, issues.length * 0.25);
  }

  double _calculateReputationRiskScore(List<String> issues) {
    return min(0.9, issues.length * 0.3);
  }

  double _calculateVelocityRiskScore(List<String> issues) {
    return min(0.8, issues.length * 0.2);
  }

  double _calculateHighValueRiskScore(List<String> issues, double amount) {
    return min(0.9, issues.length * 0.3 + (amount > 1000 ? 0.2 : 0));
  }

  double _calculateRushOrderRiskScore(List<String> issues) {
    return min(0.7, issues.length * 0.25);
  }

  double _calculateOverallRiskScore(List<FraudAnalysisCheck> checks) {
    if (checks.isEmpty) return 0.5;

    final weightedScore = checks.fold<double>(0, (sum, check) => sum + check.riskScore * _getCheckWeight(check.checkType));
    final totalWeight = checks.fold<double>(0, (sum, check) => sum + _getCheckWeight(check.checkType));

    return weightedScore / totalWeight;
  }

  double _getCheckWeight(FraudCheckType type) {
    switch (type) {
      case FraudCheckType.craftPricing:
        return 0.3;
      case FraudCheckType.customOrder:
        return 0.25;
      case FraudCheckType.seasonalPattern:
        return 0.15;
      case FraudCheckType.materialCost:
        return 0.2;
      case FraudCheckType.creatorReputation:
        return 0.2;
      case FraudCheckType.transactionVelocity:
        return 0.15;
      case FraudCheckType.highValueItem:
        return 0.25;
      case FraudCheckType.rushOrder:
        return 0.1;
      default:
        return 0.1;
    }
  }

  FraudRiskLevel _determineRiskLevel(double score) {
    if (score >= 0.8) return FraudRiskLevel.critical;
    if (score >= 0.6) return FraudRiskLevel.high;
    if (score >= 0.4) return FraudRiskLevel.medium;
    return FraudRiskLevel.low;
  }

  FraudAction _determineRequiredAction(FraudRiskLevel level, List<FraudAnalysisCheck> checks) {
    if (level == FraudRiskLevel.critical) return FraudAction.block;
    if (level == FraudRiskLevel.high) return FraudAction.manualReview;
    if (level == FraudRiskLevel.medium) return FraudAction.additionalVerification;
    return FraudAction.approve;
  }

  List<String> _generateRiskFactors(List<FraudAnalysisCheck> checks) {
    final factors = <String>[];

    for (final check in checks) {
      if (!check.passed) {
        factors.add(check.checkType.name);
      }
    }

    return factors;
  }

  List<String> _generateCraftSpecificInsights(List<FraudAnalysisCheck> checks) {
    final insights = <String>[];

    for (final check in checks) {
      if (check.details['pricing_issues'] != null) {
        final issues = check.details['pricing_issues'] as List<String>;
        if (issues.isNotEmpty) {
          insights.add('Craft pricing anomalies detected: ${issues.join(", ")}');
        }
      }

      if (check.details['seasonal_factors'] != null) {
        final factors = check.details['seasonal_factors'] as List<String>;
        if (factors.isNotEmpty) {
          insights.add('Seasonal patterns suggest elevated risk: ${factors.join(", ")}');
        }
      }
    }

    return insights;
  }

  Future<void> _updateUserHistory(String userId, FraudAnalysisResult result) async {
    if (!_userHistories.containsKey(userId)) {
      _userHistories[userId] = TransactionHistory(userId: userId);
    }

    final history = _userHistories[userId]!;
    history.addAnalysis(result);
  }

  // Additional helper methods (simplified for brevity)
  bool _isPeakSeason(DateTime date) => date.month >= 11 || date.month <= 2;
  bool _isHolidaySeason(DateTime date) => date.month == 12 && date.day >= 15;
  double _getSeasonalMultiplier(DateTime date) => _isPeakSeason(date) ? 1.2 : 1.0;
  double _getMaterialBaseCost(String material) => _materialPrices[material]?.baseCost ?? 10.0;
  double _getReasonablePriceMultiplier(int materialCount) => 2.0 + (materialCount * 0.5);
  bool _hasSuspiciousMaterialCombination(List materials) => materials.length > 5;

  Future<double> _getCreatorReputationScore(String creatorId) async => 0.7;
  Future<int> _getRecentComplaints(String creatorId) async => 1;
  Future<Duration> _getCreatorAccountAge(String creatorId) async => Duration(days: 180);
}

// Data models for craft fraud detection

class FraudAnalysisResult {
  final double overallRiskScore;
  final FraudRiskLevel riskLevel;
  final FraudAction requiredAction;
  final List<FraudAnalysisCheck> analysisChecks;
  final List<String> riskFactors;
  final bool requiresManualReview;
  final List<String> craftSpecificInsights;
  final DateTime timestamp;

  FraudAnalysisResult({
    required this.overallRiskScore,
    required this.riskLevel,
    required this.requiredAction,
    required this.analysisChecks,
    required this.riskFactors,
    required this.requiresManualReview,
    required this.craftSpecificInsights,
    required this.timestamp,
  });
}

class FraudAnalysisCheck {
  final FraudCheckType checkType;
  final double riskScore;
  final bool passed;
  final Map<String, dynamic> details;

  FraudAnalysisCheck({
    required this.checkType,
    required this.riskScore,
    required this.passed,
    required this.details,
  });
}

enum FraudCheckType {
  craftPricing,
  customOrder,
  seasonalPattern,
  materialCost,
  creatorReputation,
  transactionVelocity,
  highValueItem,
  rushOrder,
}

enum FraudAction {
  approve,
  additionalVerification,
  manualReview,
  block,
}

enum FraudRiskLevel {
  low,
  medium,
  high,
  critical,
}

class CraftFraudPattern {
  final String name;
  final String description;
  final double baseRiskScore;

  CraftFraudPattern({
    required this.name,
    required this.description,
    required this.baseRiskScore,
  });
}

class MaterialPriceData {
  final double baseCost;
  final double volatility;

  MaterialPriceData({
    required this.baseCost,
    required this.volatility,
  });
}

class PriceRange {
  final double min;
  final double max;

  PriceRange({
    required this.min,
    required this.max,
  });
}

class TransactionHistory {
  final String userId;
  final List<TransactionRecord> transactions = [];
  final List<CustomOrderRecord> customOrders = [];
  final List<FraudAnalysisResult> analyses = [];

  TransactionHistory({required this.userId});

  void addAnalysis(FraudAnalysisResult result) {
    analyses.add(result);
  }
}

class TransactionRecord {
  final double amount;
  final DateTime timestamp;
  final String paymentId;

  TransactionRecord({
    required this.amount,
    required this.timestamp,
    required this.paymentId,
  });
}

class CustomOrderRecord {
  final String orderId;
  final DateTime timestamp;
  final List<String> customizations;
  final int deliveryDays;

  CustomOrderRecord({
    required this.orderId,
    required this.timestamp,
    required this.customizations,
    required this.deliveryDays,
  });
}