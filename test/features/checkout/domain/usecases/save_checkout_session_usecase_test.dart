import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:video_window/features/checkout/domain/usecases/save_checkout_session_usecase.dart';
import 'package:video_window/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:video_window/features/checkout/domain/models/checkout_session_model.dart';
import 'package:video_window/features/checkout/domain/models/checkout_security_model.dart';
import 'package:video_window/core/error/failure.dart';

class MockCheckoutRepository extends Mock implements CheckoutRepository {}

void main() {
  late SaveCheckoutSessionUseCase useCase;
  late MockCheckoutRepository mockRepository;

  setUp(() {
    mockRepository = MockCheckoutRepository();
    useCase = SaveCheckoutSessionUseCase(mockRepository);
  });

  group('SaveCheckoutSessionUseCase', () {
    group('call', () {
      test('should save session successfully when security validation passes', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final stepData = {
          CheckoutStepType.shipping: {'address': '123 Test St'},
          CheckoutStepType.payment: {'method': 'credit_card'},
        };
        final securityContext = SecurityContextModel(
          sessionId: sessionId,
          userId: 'user123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Browser',
          deviceFingerprint: 'test-fingerprint',
          riskLevel: RiskLevel.low,
          validationTimestamp: DateTime.now(),
        );

        final securityValidation = SecurityValidationResult(
          isValid: true,
          violations: [],
          recommendedLevel: SecurityLevel.standard,
          recommendations: {},
          validatedAt: DateTime.now(),
        );

        when(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).thenAnswer((_) async => Right(securityValidation));

        when(() => mockRepository.saveSessionProgress(
          sessionId: sessionId,
          stepData: stepData,
        )).thenAnswer((_) async => const Right(true));

        // Act
        final result = await useCase.call(
          sessionId: sessionId,
          stepData: stepData,
          securityContext: securityContext,
        );

        // Assert
        expect(result, equals(const Right(true)));
        verify(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).called(1);
        verify(() => mockRepository.saveSessionProgress(
          sessionId: sessionId,
          stepData: stepData,
        )).called(1);
      });

      test('should return security failure when validation fails', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final stepData = {
          CheckoutStepType.shipping: {'address': '123 Test St'},
        };
        final securityContext = SecurityContextModel(
          sessionId: sessionId,
          userId: 'user123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Browser',
          deviceFingerprint: 'test-fingerprint',
          riskLevel: RiskLevel.high,
          validationTimestamp: DateTime.now(),
        );

        final securityValidation = SecurityValidationResult(
          isValid: false,
          violations: ['High risk detected'],
          recommendedLevel: SecurityLevel.enhanced,
          recommendations: {},
          validatedAt: DateTime.now(),
        );

        when(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).thenAnswer((_) async => Right(securityValidation));

        // Act
        final result = await useCase.call(
          sessionId: sessionId,
          stepData: stepData,
          securityContext: securityContext,
        );

        // Assert
        expect(result, isA<Left<Failure, bool>>());
        final failure = result.fold((l) => l, (r) => null);
        expect(failure, isA<SecurityFailure>());
        expect(failure?.message, equals('Security validation failed'));
        verify(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).called(1);
        verifyNever(() => mockRepository.saveSessionProgress(
          sessionId: any(named: 'sessionId'),
          stepData: any(named: 'stepData'),
        ));
      });

      test('should return repository failure when security validation fails', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final stepData = {
          CheckoutStepType.shipping: {'address': '123 Test St'},
        };
        final securityContext = SecurityContextModel(
          sessionId: sessionId,
          userId: 'user123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Browser',
          deviceFingerprint: 'test-fingerprint',
          riskLevel: RiskLevel.low,
          validationTimestamp: DateTime.now(),
        );

        when(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).thenAnswer((_) async => Left(ServerFailure('Security service unavailable')));

        // Act
        final result = await useCase.call(
          sessionId: sessionId,
          stepData: stepData,
          securityContext: securityContext,
        );

        // Assert
        expect(result, isA<Left<Failure, bool>>());
        final failure = result.fold((l) => l, (r) => null);
        expect(failure, isA<ServerFailure>());
        expect(failure?.message, equals('Security service unavailable'));
        verify(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).called(1);
        verifyNever(() => mockRepository.saveSessionProgress(
          sessionId: any(named: 'sessionId'),
          stepData: any(named: 'stepData'),
        ));
      });

      test('should return repository failure when save fails', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final stepData = {
          CheckoutStepType.shipping: {'address': '123 Test St'},
        };
        final securityContext = SecurityContextModel(
          sessionId: sessionId,
          userId: 'user123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Browser',
          deviceFingerprint: 'test-fingerprint',
          riskLevel: RiskLevel.low,
          validationTimestamp: DateTime.now(),
        );

        final securityValidation = SecurityValidationResult(
          isValid: true,
          violations: [],
          recommendedLevel: SecurityLevel.standard,
          recommendations: {},
          validatedAt: DateTime.now(),
        );

        when(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).thenAnswer((_) async => Right(securityValidation));

        when(() => mockRepository.saveSessionProgress(
          sessionId: sessionId,
          stepData: stepData,
        )).thenAnswer((_) async => Left(CacheFailure('Unable to save session')));

        // Act
        final result = await useCase.call(
          sessionId: sessionId,
          stepData: stepData,
          securityContext: securityContext,
        );

        // Assert
        expect(result, isA<Left<Failure, bool>>());
        final failure = result.fold((l) => l, (r) => null);
        expect(failure, isA<CacheFailure>());
        expect(failure?.message, equals('Unable to save session'));
        verify(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).called(1);
        verify(() => mockRepository.saveSessionProgress(
          sessionId: sessionId,
          stepData: stepData,
        )).called(1);
      });

      test('should handle empty step data', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final stepData = <CheckoutStepType, Map<String, dynamic>>{};
        final securityContext = SecurityContextModel(
          sessionId: sessionId,
          userId: 'user123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Browser',
          deviceFingerprint: 'test-fingerprint',
          riskLevel: RiskLevel.low,
          validationTimestamp: DateTime.now(),
        );

        final securityValidation = SecurityValidationResult(
          isValid: true,
          violations: [],
          recommendedLevel: SecurityLevel.standard,
          recommendations: {},
          validatedAt: DateTime.now(),
        );

        when(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).thenAnswer((_) async => Right(securityValidation));

        when(() => mockRepository.saveSessionProgress(
          sessionId: sessionId,
          stepData: stepData,
        )).thenAnswer((_) async => const Right(true));

        // Act
        final result = await useCase.call(
          sessionId: sessionId,
          stepData: stepData,
          securityContext: securityContext,
        );

        // Assert
        expect(result, equals(const Right(true)));
        verify(() => mockRepository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        )).called(1);
        verify(() => mockRepository.saveSessionProgress(
          sessionId: sessionId,
          stepData: stepData,
        )).called(1);
      });
    });
  });
}