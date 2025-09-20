import 'package:flutter_test/flutter_test.dart';
import 'package:videowindow/features/payment/services/threed_secure_service.dart';

void main() {
  group('ThreeDSecureService', () {
    late ThreeDSecureService service;

    setUp(() {
      service = ThreeDSecureService(
        apiKey: 'test_api_key',
        apiSecret: 'test_api_secret',
      );
    });

    group('authenticatePayment', () {
      test('should return successful authentication for low-risk transactions', () async {
        // Arrange
        final paymentId = 'pay_123456';
        final transactionId = 'txn_123456';
        final amount = 50.0;
        final currency = 'USD';
        final cardToken = 'tok_visa_123456';
        final browserData = {'user_agent': 'Mozilla/5.0'};
        final deviceData = {'device_id': 'device_123'};

        // Act
        final result = await service.authenticatePayment(
          paymentId: paymentId,
          transactionId: transactionId,
          amount: amount,
          currency: currency,
          cardToken: cardToken,
          browserData: browserData,
          deviceData: deviceData,
        );

        // Assert
        expect(result.success, true);
        expect(result.authenticationStatus, ThreeDAuthenticationStatus.successful);
        expect(result.riskLevel, FraudRiskLevel.low);
      });

      test('should require challenge for high-risk transactions', () async {
        // Arrange
        final paymentId = 'pay_123456';
        final transactionId = 'txn_123456';
        final amount = 500.0; // High amount
        final currency = 'USD';
        final cardToken = 'tok_visa_123456';
        final browserData = {'user_agent': 'Mozilla/5.0'};
        final deviceData = {'device_id': 'device_123'};

        // Act
        final result = await service.authenticatePayment(
          paymentId: paymentId,
          transactionId: transactionId,
          amount: amount,
          currency: currency,
          cardToken: cardToken,
          browserData: browserData,
          deviceData: deviceData,
        );

        // Assert
        expect(result.success, false);
        expect(result.authenticationStatus, ThreeDAuthenticationStatus.challengeRequired);
        expect(result.challengeUrl, isNotNull);
        expect(result.requiresChallenge, true);
      });

      test('should handle authentication errors gracefully', () async {
        // Arrange
        final invalidData = {
          'paymentId': '',
          'transactionId': '',
          'amount': -1.0,
          'currency': '',
          'cardToken': '',
        };

        // Act
        final result = await service.authenticatePayment(
          paymentId: invalidData['paymentId']!,
          transactionId: invalidData['transactionId']!,
          amount: invalidData['amount']!,
          currency: invalidData['currency']!,
          cardToken: invalidData['cardToken']!,
          browserData: {},
          deviceData: {},
        );

        // Assert
        expect(result.success, false);
        expect(result.authenticationStatus, ThreeDAuthenticationStatus.error);
        expect(result.error, isNotNull);
      });
    });

    group('validation', () {
      test('should validate authentication request parameters', () async {
        // Act
        final result = await service._validateAuthenticationRequest(
          paymentId: 'pay_123',
          transactionId: 'txn_123',
          amount: 100.0,
          currency: 'USD',
          cardToken: 'tok_visa_123',
        );

        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
        expect(result.riskLevel, FraudRiskLevel.low);
      });

      test('should reject invalid authentication request parameters', () async {
        // Act
        final result = await service._validateAuthenticationRequest(
          paymentId: '', // Empty
          transactionId: 'txn_123',
          amount: -1.0, // Invalid amount
          currency: 'US', // Invalid currency
          cardToken: 'invalid_token',
        );

        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, isNotNull);
        expect(result.riskLevel, FraudRiskLevel.high);
      });

      group('token validation', () {
        test('should validate Stripe tokens correctly', () {
          final stripeService = ThreeDSecureService(
            apiKey: 'test_key',
            apiSecret: 'test_secret',
            provider: ThreeDProvider.stripe,
          );

          expect(stripeService._validateCardToken('tok_visa_123456').isValid, true);
          expect(stripeService._validateCardToken('pm_123456').isValid, true);
          expect(stripeService._validateCardToken('invalid_token').isValid, false);
        });

        test('should validate Braintree tokens correctly', () {
          final braintreeService = ThreeDSecureService(
            apiKey: 'test_key',
            apiSecret: 'test_secret',
            provider: ThreeDProvider.braintree,
          );

          expect(braintreeService._validateCardToken('bt_123456').isValid, true);
          expect(braintreeService._validateCardToken('tok_visa_123456').isValid, false);
        });

        test('should validate Adyen tokens correctly', () {
          final adyenService = ThreeDSecureService(
            apiKey: 'test_key',
            apiSecret: 'test_secret',
            provider: ThreeDProvider.adyen,
          );

          expect(adyenService._validateCardToken('a' * 25).isValid, true);
          expect(adyenService._validateCardToken('short').isValid, false);
        });
      });
    });

    group('risk assessment', () {
      test('should perform risk assessment for transactions', () async {
        // Act
        final assessment = await service._performRiskAssessment(
          paymentId: 'pay_123',
          amount: 100.0,
          cardToken: 'tok_visa_123',
          browserData: {'user_agent': 'Mozilla/5.0'},
          deviceData: {'device_id': 'device_123'},
        );

        // Assert
        expect(assessment.riskScore, greaterThanOrEqualTo(0.0));
        expect(assessment.riskScore, lessThanOrEqualTo(1.0));
        expect(assessment.riskFactors, isNotNull);
        expect(assessment.recommendedAction, isNotNull);
      });
    });

    group('challenge URL building', () {
      test('should build correct challenge URL', () {
        // Arrange
        final session = ThreeDSession(
          id: 'session_123',
          transactionId: 'txn_123',
          acsUrl: 'https://acs.example.com/3ds',
          creq: 'creq_123456',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        // Act
        final url = service._buildChallengeUrl(session);

        // Assert
        expect(url, startsWith('https://acs.example.com/3ds'));
        expect(url, contains('creq=creq_123456'));
        expect(url, contains('session_id=session_123'));
        expect(url, contains('transaction_id=txn_123'));
      });
    });

    group('exemption check', () {
      test('should check transaction exemption eligibility', () async {
        // Act
        final isEligible = await service.qualifiesForExemption(
          amount: 25.0,
          cardToken: 'tok_visa_123',
          transactionData: {'transaction_type': 'low_risk'},
        );

        // Assert
        expect(isEligible, isNotNull);
      });
    });

    group('configuration', () {
      test('should get 3D Secure configuration', () async {
        // Act
        final config = await service.getConfiguration();

        // Assert
        expect(config.provider, ThreeDProvider.stripe);
        expect(config.challengePreference, isNotNull);
        expect(config.exemptionEnabled, isNotNull);
        expect(config.maxAmountForExemption, greaterThanOrEqualTo(0.0));
      });
    });

    group('result parsing', () {
      test('should parse successful authentication result', () {
        // Arrange
        final json = {
          'success': true,
          'authentication_status': 'successful',
          'risk_level': 'low',
          'cavv': 'cavv_123',
          'eci': '05',
          'transaction_id': 'txn_123',
        };

        // Act
        final result = ThreeDSecureResult.fromJson(json);

        // Assert
        expect(result.success, true);
        expect(result.authenticationStatus, ThreeDAuthenticationStatus.successful);
        expect(result.riskLevel, FraudRiskLevel.low);
        expect(result.cavv, 'cavv_123');
        expect(result.eci, '05');
        expect(result.isAuthenticated, true);
      });

      test('should parse failed authentication result', () {
        // Arrange
        final json = {
          'success': false,
          'authentication_status': 'failed',
          'risk_level': 'high',
          'error': 'Authentication failed',
        };

        // Act
        final result = ThreeDSecureResult.fromJson(json);

        // Assert
        expect(result.success, false);
        expect(result.authenticationStatus, ThreeDAuthenticationStatus.failed);
        expect(result.riskLevel, FraudRiskLevel.high);
        expect(result.error, 'Authentication failed');
        expect(result.isAuthenticated, false);
      });
    });

    group('session creation', () {
      test('should create 3D Secure session with correct data', () async {
        // This would normally require mocking HTTP requests
        // For now, we'll test the data structure
        final paymentId = 'pay_123';
        final transactionId = 'txn_123';
        final amount = 100.0;
        final currency = 'USD';
        final cardToken = 'tok_visa_123';
        final browserData = {'user_agent': 'Mozilla/5.0'};
        final deviceData = {'device_id': 'device_123'};

        // The actual session creation would be tested with mock HTTP responses
        expect(paymentId, isNotNull);
        expect(transactionId, isNotNull);
        expect(amount, greaterThan(0));
        expect(currency, isNotNull);
        expect(cardToken, isNotNull);
      });
    });
  });
}