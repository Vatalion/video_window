import 'package:flutter_test/flutter_test.dart';
import 'package:videowindow/features/payment/services/craft_fraud_detection_service.dart';

void main() {
  group('CraftFraudDetectionService', () {
    late CraftFraudDetectionService service;

    setUp(() {
      service = CraftFraudDetectionService();
    });

    group('analyzePaymentRisk', () {
      test('should analyze payment risk with craft-specific patterns', () async {
        // Arrange
        final userId = 'user_123';
        final paymentId = 'pay_123456';
        final amount = 125.0; // Craft commerce AOV
        final currency = 'USD';
        final transactionData = {
          'items': [
            {
              'type': 'handmade_jewelry',
              'price': 125.0,
              'materials': [
                {'type': 'silver', 'quantity': 1},
                {'type': 'gemstone', 'quantity': 2},
              ]
            }
          ],
          'is_custom_order': true,
          'customizations': ['engraving', 'size_adjustment'],
          'creator_id': 'creator_123',
          'delivery_days': 7,
        };
        final userData = {
          'account_age_days': 180,
          'total_orders': 5,
        };

        // Act
        final result = await service.analyzePaymentRisk(
          userId: userId,
          paymentId: paymentId,
          amount: amount,
          currency: currency,
          transactionData: transactionData,
          userData: userData,
          ipAddress: '192.168.1.1',
          deviceId: 'device_123',
          userAgent: 'Mozilla/5.0',
        );

        // Assert
        expect(result.overallRiskScore, greaterThanOrEqualTo(0.0));
        expect(result.overallRiskScore, lessThanOrEqualTo(1.0));
        expect(result.analysisChecks.length, 8); // All 8 checks should be performed
        expect(result.riskLevel, isNotNull);
        expect(result.requiredAction, isNotNull);
        expect(result.craftSpecificInsights, isNotNull);
      });

      test('should flag high-risk transactions', () async {
        // Arrange
        final transactionData = {
          'items': [
            {
              'type': 'handmade_jewelry',
              'price': 1000.0, // Very high value
              'materials': [
                {'type': 'gold', 'quantity': 10},
              ]
            }
          ],
          'is_custom_order': true,
          'customizations': List.filled(15, 'custom'), // Excessive customizations
          'is_rush_order': true,
          'delivery_days': 1, // Impossible delivery
          'rush_fee': 200.0, // Excessive rush fee
        };

        // Act
        final result = await service.analyzePaymentRisk(
          userId: 'user_123',
          paymentId: 'pay_123456',
          amount: 1200.0,
          currency: 'USD',
          transactionData: transactionData,
          userData: {},
        );

        // Assert
        expect(result.overallRiskScore, greaterThanOrEqualTo(0.7));
        expect(result.riskLevel, FraudRiskLevel.high);
        expect(result.requiresManualReview, true);
      });

      test('should approve low-risk transactions', () async {
        // Arrange
        final transactionData = {
          'items': [
            {
              'type': 'accessory',
              'price': 25.0,
              'materials': [
                {'type': 'fabric', 'quantity': 1},
              ]
            }
          ],
          'is_custom_order': false,
          'creator_id': 'creator_123',
          'delivery_days': 14,
        };

        // Act
        final result = await service.analyzePaymentRisk(
          userId: 'user_123',
          paymentId: 'pay_123456',
          amount: 25.0,
          currency: 'USD',
          transactionData: transactionData,
          userData: {
            'account_age_days': 365,
            'total_orders': 20,
          },
        );

        // Assert
        expect(result.overallRiskScore, lessThan(0.4));
        expect(result.riskLevel, FraudRiskLevel.low);
        expect(result.requiredAction, FraudAction.approve);
      });
    });

    group('craft price analysis', () {
      test('should flag round number pricing', () async {
        // Act
        final result = await service._analyzeCraftPrice(
          amount: 100.0, // Round number
          currency: 'USD',
          transactionData: {
            'items': [
              {'price': 100.0, 'type': 'handmade_jewelry'}
            ]
          },
        );

        // Assert
        expect(result.riskScore, greaterThan(0.3));
        expect(result.details['pricing_issues'], contains('round_number_pricing'));
      });

      test('should flag prices outside expected range', () async {
        // Act
        final result = await service._analyzeCraftPrice(
          amount: 2000.0, // Very high for craft
          currency: 'USD',
          transactionData: {
            'items': [
              {'price': 2000.0, 'type': 'accessory'}
            ]
          },
        );

        // Assert
        expect(result.riskScore, greaterThan(0.5));
        expect(result.details['pricing_issues'], contains('price_outside_expected_range'));
      });
    });

    group('custom order analysis', () {
      test('should flag suspicious custom orders', () async {
        // Act
        final result = await service._analyzeCustomOrderPattern(
          userId: 'user_123',
          transactionData: {
            'is_custom_order': true,
            'customizations': [], // No customizations
            'delivery_days': 1, // Unrealistic delivery
          },
          userData: {},
        );

        // Assert
        expect(result.riskScore, greaterThan(0.5));
        expect(result.details['risk_factors'], contains('custom_order_no_customizations'));
        expect(result.details['risk_factors'], contains('unrealistic_custom_delivery'));
      });

      test('should flag excessive customizations', () async {
        // Act
        final result = await service._analyzeCustomOrderPattern(
          userId: 'user_123',
          transactionData: {
            'is_custom_order': true,
            'customizations': List.filled(15, 'custom'), // Too many
            'delivery_days': 14,
          },
          userData: {},
        );

        // Assert
        expect(result.riskScore, greaterThan(0.4));
        expect(result.details['risk_factors'], contains('excessive_customizations'));
      });
    });

    group('seasonal pattern analysis', () {
      test('should analyze seasonal pricing patterns', () async {
        // Act
        final result = await service._analyzeSeasonalPattern(
          amount: 800.0,
          transactionData: {},
        );

        // Assert
        expect(result.riskScore, greaterThanOrEqualTo(0.0));
        expect(result.details['seasonal_multiplier'], greaterThan(0.0));
        expect(result.details['is_peak_season'], isNotNull);
      });

      test('should flag off-season high-value purchases', () async {
        // Act
        final result = await service._analyzeSeasonalPattern(
          amount: 900.0, // High value
          transactionData: {},
        );

        // Assert
        expect(result.details['seasonal_factors'], contains('high_value_off_season'));
      });
    });

    group('material cost analysis', () {
      test('should flag pricing below material costs', () async {
        // Act
        final result = await service._analyzeMaterialCosts(
          amount: 10.0, // Too low for materials
          transactionData: {
            'items': [
              {
                'price': 10.0,
                'materials': [
                  {'type': 'gold', 'quantity': 1}, // Gold costs more
                ]
              }
            ]
          },
        );

        // Assert
        expect(result.riskScore, greaterThan(0.5));
        expect(result.details['material_cost_issues'], contains('price_below_material_cost'));
      });

      test('should flag suspicious material combinations', () async {
        // Act
        final result = await service._analyzeMaterialCosts(
          amount: 500.0,
          transactionData: {
            'items': [
              {
                'price': 500.0,
                'materials': List.filled(6, {'type': 'gold', 'quantity': 1}), // Too many
              }
            ]
          },
        );

        // Assert
        expect(result.details['material_cost_issues'], contains('suspicious_material_combination'));
      });
    });

    group('creator reputation analysis', () {
      test('should flag low reputation creators', () async {
        // Act
        final result = await service._analyzeCreatorReputation(
          userId: 'user_123',
          transactionData: {
            'creator_id': 'creator_123',
          },
        );

        // Assert
        expect(result.riskScore, greaterThanOrEqualTo(0.0));
        expect(result.details['creator_id'], isNotNull);
      });

      test('should flag missing creator information', () async {
        // Act
        final result = await service._analyzeCreatorReputation(
          userId: 'user_123',
          transactionData: {}, // No creator_id
        );

        // Assert
        expect(result.details['reputation_issues'], contains('missing_creator_information'));
      });
    });

    group('transaction velocity analysis', () {
      test('should flag high transaction frequency', () async {
        // Act
        final result = await service._analyzeCraftTransactionVelocity(
          userId: 'user_123',
          amount: 200.0,
          ipAddress: '192.168.1.1',
          deviceId: 'device_123',
        );

        // Assert
        expect(result.riskScore, greaterThanOrEqualTo(0.0));
        expect(result.details['user_history_available'], isNotNull);
      });
    });

    group('high-value item analysis', () {
      test('should flag high-value jewelry', () async {
        // Act
        final result = await service._analyzeHighValueItems(
          amount: 2500.0,
          transactionData: {
            'items': [
              {
                'type': 'jewelry',
                'price': 2500.0,
              }
            ]
          },
        );

        // Assert
        expect(result.details['high_value_issues'], contains('high_value_jewelry'));
        expect(result.riskScore, greaterThan(0.5));
      });

      test('should flag first purchase high value', () async {
        // Act
        final result = await service._analyzeHighValueItems(
          amount: 1500.0,
          transactionData: {
            'is_first_purchase': true,
            'items': [
              {
                'type': 'furniture',
                'price': 1500.0,
              }
            ]
          },
        );

        // Assert
        expect(result.details['high_value_issues'], contains('first_purchase_high_value'));
      });
    });

    group('rush order analysis', () {
      test('should flag excessive rush fees', () async {
        // Act
        final result = await service._analyzeRushOrder(
          transactionData: {
            'is_rush_order': true,
            'rush_fee': 150.0, // Excessive
            'delivery_days': 3,
          },
        );

        // Assert
        expect(result.details['rush_order_issues'], contains('excessive_rush_fee'));
        expect(result.riskScore, greaterThan(0.3));
      });

      test('should flag impossible delivery times', () async {
        // Act
        final result = await service._analyzeRushOrder(
          transactionData: {
            'is_rush_order': true,
            'delivery_days': 0, // Impossible
          },
        );

        // Assert
        expect(result.details['rush_order_issues'], contains('impossible_delivery_time'));
      });
    });

    group('risk scoring', () {
      test('should calculate correct overall risk score', () {
        // Arrange
        final checks = [
          FraudAnalysisCheck(
            checkType: FraudCheckType.craftPricing,
            riskScore: 0.3,
            passed: true,
            details: {},
          ),
          FraudAnalysisCheck(
            checkType: FraudCheckType.customOrder,
            riskScore: 0.7,
            passed: false,
            details: {},
          ),
        ];

        // Act
        final score = service._calculateOverallRiskScore(checks);

        // Assert
        expect(score, greaterThanOrEqualTo(0.3));
        expect(score, lessThanOrEqualTo(0.7));
      });

      test('should determine correct risk level', () {
        expect(service._determineRiskLevel(0.2), FraudRiskLevel.low);
        expect(service._determineRiskLevel(0.5), FraudRiskLevel.medium);
        expect(service._determineRiskLevel(0.7), FraudRiskLevel.high);
        expect(service._determineRiskLevel(0.9), FraudRiskLevel.critical);
      });

      test('should determine correct required action', () {
        expect(service._determineRequiredAction(FraudRiskLevel.low, []), FraudAction.approve);
        expect(service._determineRequiredAction(FraudRiskLevel.medium, []), FraudAction.additionalVerification);
        expect(service._determineRequiredAction(FraudRiskLevel.high, []), FraudAction.manualReview);
        expect(service._determineRequiredAction(FraudRiskLevel.critical, []), FraudAction.block);
      });
    });

    group('craft-specific insights', () {
      test('should generate craft-specific insights', () {
        // Arrange
        final checks = [
          FraudAnalysisCheck(
            checkType: FraudCheckType.craftPricing,
            riskScore: 0.8,
            passed: false,
            details: {
              'pricing_issues': ['round_number_pricing', 'price_outside_expected_range'],
            },
          ),
          FraudAnalysisCheck(
            checkType: FraudCheckType.seasonalPattern,
            riskScore: 0.6,
            passed: false,
            details: {
              'seasonal_factors': ['high_value_off_season'],
            },
          ),
        ];

        // Act
        final insights = service._generateCraftSpecificInsights(checks);

        // Assert
        expect(insights, isNotEmpty);
        expect(insights.any((insight) => insight.contains('Craft pricing anomalies')), true);
        expect(insights.any((insight) => insight.contains('Seasonal patterns')), true);
      });
    });
  });
}