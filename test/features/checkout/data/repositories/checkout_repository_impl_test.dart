import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:video_window/features/checkout/data/datasources/checkout_local_data_source.dart';
import 'package:video_window/features/checkout/data/datasources/checkout_remote_data_source.dart';
import 'package:video_window/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:video_window/features/checkout/domain/models/checkout_session_model.dart';
import 'package:video_window/features/checkout/domain/models/checkout_security_model.dart';
import 'package:video_window/core/error/failure.dart';

class MockCheckoutLocalDataSource extends Mock implements CheckoutLocalDataSource {}
class MockCheckoutRemoteDataSource extends Mock implements CheckoutRemoteDataSource {}

void main() {
  late CheckoutRepositoryImpl repository;
  late MockCheckoutLocalDataSource mockLocalDataSource;
  late MockCheckoutRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockCheckoutLocalDataSource();
    mockRemoteDataSource = MockCheckoutRemoteDataSource();
    repository = CheckoutRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('CheckoutRepositoryImpl', () {
    group('saveSessionProgress', () {
      test('should save session progress successfully', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final stepData = {
          CheckoutStepType.shipping: {'address': '123 Test St'},
          CheckoutStepType.payment: {'method': 'credit_card'},
        };

        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.saveSessionProgress(
          sessionId: sessionId,
          stepData: stepData,
        );

        // Assert
        expect(result, equals(const Right(true)));
        verify(() => mockLocalDataSource.saveSession(any())).called(1);
      });

      test('should return failure when save fails', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final stepData = {
          CheckoutStepType.shipping: {'address': '123 Test St'},
        };

        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.saveSessionProgress(
          sessionId: sessionId,
          stepData: stepData,
        );

        // Assert
        expect(result, isA<Left<Failure, bool>>());
      });
    });

    group('getSession', () {
      test('should return session when found', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final expectedSession = CheckoutSessionModel(
          sessionId: sessionId,
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        when(() => mockLocalDataSource.getSession(sessionId))
            .thenAnswer((_) async => expectedSession);

        // Act
        final result = await repository.getSession(sessionId);

        // Assert
        expect(result, equals(Right(expectedSession)));
        verify(() => mockLocalDataSource.getSession(sessionId)).called(1);
      });

      test('should return failure when session not found', () async {
        // Arrange
        final sessionId = 'non-existent-session';

        when(() => mockLocalDataSource.getSession(sessionId))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getSession(sessionId);

        // Assert
        expect(result, isA<Left<Failure, CheckoutSessionModel>>());
      });
    });

    group('validateSecurityContext', () {
      test('should validate security context successfully', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final securityContext = SecurityContextModel(
          sessionId: sessionId,
          userId: 'user123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Browser',
          deviceFingerprint: 'test-fingerprint',
          riskLevel: RiskLevel.low,
          validationTimestamp: DateTime.now(),
        );

        when(() => mockRemoteDataSource.validateSecurity(securityContext))
            .thenAnswer((_) async => SecurityValidationResult(
              isValid: true,
              violations: [],
              recommendedLevel: SecurityLevel.standard,
              recommendations: {},
              validatedAt: DateTime.now(),
            ));

        // Act
        final result = await repository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        );

        // Assert
        expect(result, isA<Right<Failure, SecurityValidationResult>>());
        verify(() => mockRemoteDataSource.validateSecurity(securityContext)).called(1);
      });

      test('should return failure when security validation fails', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final securityContext = SecurityContextModel(
          sessionId: sessionId,
          userId: 'user123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Browser',
          deviceFingerprint: 'test-fingerprint',
          riskLevel: RiskLevel.high,
          validationTimestamp: DateTime.now(),
        );

        when(() => mockRemoteDataSource.validateSecurity(securityContext))
            .thenAnswer((_) async => SecurityValidationResult(
              isValid: false,
              violations: ['High risk detected'],
              recommendedLevel: SecurityLevel.enhanced,
              recommendations: {},
              validatedAt: DateTime.now(),
            ));

        // Act
        final result = await repository.validateSecurityContext(
          sessionId: sessionId,
          context: securityContext,
        );

        // Assert
        expect(result, isA<Right<Failure, SecurityValidationResult>>());
        final validation = result.getOrElse(() => throw Exception());
        expect(validation.isValid, isFalse);
      });
    });

    group('resumeCheckout', () {
      test('should resume checkout successfully', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final session = CheckoutSessionModel(
          sessionId: sessionId,
          userId: 'user123',
          currentStep: CheckoutStepType.payment,
          stepData: {
            CheckoutStepType.shipping: {'address': '123 Test St'},
          },
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          expiresAt: DateTime.now().add(const Duration(hours: 23)),
        );

        when(() => mockLocalDataSource.getSession(sessionId))
            .thenAnswer((_) async => session);
        when(() => mockRemoteDataSource.validateSessionResumption(sessionId))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.resumeCheckout(sessionId);

        // Assert
        expect(result, equals(Right(session)));
        verify(() => mockLocalDataSource.getSession(sessionId)).called(1);
        verify(() => mockRemoteDataSource.validateSessionResumption(sessionId)).called(1);
      });

      test('should return failure when session is expired', () async {
        // Arrange
        final sessionId = 'expired-session-id';
        final session = CheckoutSessionModel(
          sessionId: sessionId,
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(() => mockLocalDataSource.getSession(sessionId))
            .thenAnswer((_) async => session);

        // Act
        final result = await repository.resumeCheckout(sessionId);

        // Assert
        expect(result, isA<Left<Failure, CheckoutSessionModel>>());
      });
    });
  });
}