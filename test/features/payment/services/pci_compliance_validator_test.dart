import 'package:flutter_test/flutter_test.dart';
import 'package:videowindow/features/payment/services/pci_compliance_validator.dart';

void main() {
  group('PciComplianceValidator', () {
    late PciComplianceValidator validator;

    setUp(() {
      validator = PciComplianceValidator(
        apiKey: 'test_api_key',
        apiSecret: 'test_api_secret',
      );
    });

    group('validateCompliance', () {
      test('should validate compliance successfully with valid data', () async {
        // Arrange
        final merchantId = 'test_merchant_123';
        final transactionId = 'txn_123456';
        final cardData = 'tok_visa_123456789';
        final environmentData = {
          'tls_version': '1.3',
          'hsts_enabled': true,
          'secure_cookies': true,
        };

        // Act
        final result = await validator.validateCompliance(
          merchantId: merchantId,
          transactionId: transactionId,
          cardData: cardData,
          environmentData: environmentData,
        );

        // Assert
        expect(result.isValid, true);
        expect(result.score, greaterThan(90.0));
        expect(result.complianceLevel, PciComplianceLevel.level1);
        expect(result.validations.length, 5);
      });

      test('should fail validation with invalid TLS version', () async {
        // Arrange
        final environmentData = {
          'tls_version': '1.2', // Invalid version
          'hsts_enabled': true,
          'secure_cookies': true,
        };

        // Act
        final result = await validator.validateCompliance(
          merchantId: 'test_merchant_123',
          transactionId: 'txn_123456',
          cardData: 'tok_visa_123456789',
          environmentData: environmentData,
        );

        // Assert
        expect(result.isValid, false);
        expect(result.score, lessThan(80.0));
      });

      test('should fail validation with non-tokenized card data', () async {
        // Arrange
        final environmentData = {
          'tls_version': '1.3',
          'hsts_enabled': true,
          'secure_cookies': true,
        };

        // Act
        final result = await validator.validateCompliance(
          merchantId: 'test_merchant_123',
          transactionId: 'txn_123456',
          cardData: '4111111111111111', // Raw card number
          environmentData: environmentData,
        );

        // Assert
        expect(result.isValid, false);
        final dataValidation = result.validations.firstWhere((v) => v.category == 'Data Handling');
        expect(dataValidation.isValid, false);
      });

      test('should fail validation with raw card data in logs', () async {
        // Arrange
        final environmentData = {
          'tls_version': '1.3',
          'hsts_enabled': true,
          'secure_cookies': true,
        };

        // Act
        final result = await validator.validateCompliance(
          merchantId: 'test_merchant_123',
          transactionId: 'txn_123456',
          cardData: 'Card number: 4111111111111111, CVV: 123',
          environmentData: environmentData,
        );

        // Assert
        expect(result.isValid, false);
        final dataValidation = result.validations.firstWhere((v) => v.category == 'Data Handling');
        expect(dataValidation.isValid, false);
      });
    });

    group('tokenization validation', () {
      test('should recognize Stripe tokens', () {
        expect(validator._isTokenized('tok_visa_123456789'), true);
        expect(validator._isTokenized('pm_123456789'), true);
      });

      test('should recognize long tokens', () {
        expect(validator._isTokenized('a' * 35), true);
      });

      test('should reject raw card numbers', () {
        expect(validator._isTokenized('4111111111111111'), false);
        expect(validator._isTokenized('1234'), false);
      });
    });

    group('encryption validation', () {
      test('should validate encrypted data', () {
        // This is a simplified test - in practice, you'd need proper encryption
        final encryptedData = 'encrypted_data_placeholder';
        expect(validator._isEncrypted(encryptedData), false); // Should fail with placeholder
      });
    });

    group('compliance scoring', () {
      test('should calculate correct compliance score', () {
        final validations = [
          ComplianceValidation(
            category: 'Test',
            isValid: true,
            checks: [
              ValidationCheck(
                name: 'Test Check',
                passed: true,
                message: 'Passed',
                severity: ValidationSeverity.passed,
              ),
            ],
          ),
        ];

        final score = validator._calculateComplianceScore(validations);
        expect(score, 100.0);
      });

      test('should determine correct compliance level', () {
        expect(validator._determineComplianceLevel([]), PciComplianceLevel.level4);
        expect(validator._determineComplianceLevel([_createMockValidation(true)]), PciComplianceLevel.level1);
        expect(validator._determineComplianceLevel([_createMockValidation(false)]), PciComplianceLevel.level4);
      });
    });

    group('compliance result expiry', () {
      test('should detect expired compliance', () {
        final expiredResult = PciComplianceResult(
          isValid: true,
          score: 95.0,
          validations: [],
          lastValidated: DateTime.now().subtract(const Duration(hours: 25)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          complianceLevel: PciComplianceLevel.level1,
        );

        expect(expiredResult.isExpired, true);
      });

      test('should detect need for revalidation', () {
        final oldResult = PciComplianceResult(
          isValid: true,
          score: 95.0,
          validations: [],
          lastValidated: DateTime.now().subtract(const Duration(hours: 13)),
          expiresAt: DateTime.now().add(const Duration(hours: 11)),
          complianceLevel: PciComplianceLevel.level1,
        );

        expect(oldResult.needsRevalidation, true);
      });
    });
  });
}

ComplianceValidation _createMockValidation(bool isValid) {
  return ComplianceValidation(
    category: 'Test',
    isValid: isValid,
    checks: [
      ValidationCheck(
        name: 'Test Check',
        passed: isValid,
        message: isValid ? 'Passed' : 'Failed',
        severity: isValid ? ValidationSeverity.passed : ValidationSeverity.high,
      ),
    ],
  );
}