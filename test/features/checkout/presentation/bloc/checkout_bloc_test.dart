import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:video_window/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:video_window/features/checkout/presentation/bloc/checkout_event.dart';
import 'package:video_window/features/checkout/presentation/bloc/checkout_state.dart';
import 'package:video_window/features/checkout/domain/usecases/save_checkout_session_usecase.dart';
import 'package:video_window/features/checkout/domain/usecases/resume_checkout_session_usecase.dart';
import 'package:video_window/features/checkout/domain/usecases/validate_checkout_step_usecase.dart';
import 'package:video_window/features/checkout/domain/usecases/complete_checkout_usecase.dart';
import 'package:video_window/features/checkout/domain/models/checkout_session_model.dart';
import 'package:video_window/features/checkout/domain/models/checkout_security_model.dart';
import 'package:dartz/dartz.dart';
import 'package:video_window/core/error/failure.dart';

class MockSaveCheckoutSessionUseCase extends Mock implements SaveCheckoutSessionUseCase {}
class MockResumeCheckoutSessionUseCase extends Mock implements ResumeCheckoutSessionUseCase {}
class MockValidateCheckoutStepUseCase extends Mock implements ValidateCheckoutStepUseCase {}
class MockCompleteCheckoutUseCase extends Mock implements CompleteCheckoutUseCase {}

void main() {
  late CheckoutBloc checkoutBloc;
  late MockSaveCheckoutSessionUseCase mockSaveUseCase;
  late MockResumeCheckoutSessionUseCase mockResumeUseCase;
  late MockValidateCheckoutStepUseCase mockValidateUseCase;
  late MockCompleteCheckoutUseCase mockCompleteUseCase;

  setUp(() {
    mockSaveUseCase = MockSaveCheckoutSessionUseCase();
    mockResumeUseCase = MockResumeCheckoutSessionUseCase();
    mockValidateUseCase = MockValidateCheckoutStepUseCase();
    mockCompleteUseCase = MockCompleteCheckoutUseCase();
    checkoutBloc = CheckoutBloc(
      saveCheckoutSessionUseCase: mockSaveUseCase,
      resumeCheckoutSessionUseCase: mockResumeUseCase,
      validateCheckoutStepUseCase: mockValidateUseCase,
      completeCheckoutUseCase: mockCompleteUseCase,
    );
  });

  tearDown(() {
    checkoutBloc.close();
  });

  group('CheckoutBloc', () {
    group('initial state', () {
      test('should be CheckoutInitial', () {
        expect(checkoutBloc.state, equals(CheckoutInitial()));
      });
    });

    group('StartCheckout', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'emits [CheckoutLoading, CheckoutInProgress] when successful',
        build: () {
          when(() => mockResumeUseCase(any()))
              .thenAnswer((_) async => Right(CheckoutSessionModel(
                sessionId: 'test-session',
                userId: 'user123',
                currentStep: CheckoutStepType.shipping,
                stepData: {},
                createdAt: DateTime.now(),
                expiresAt: DateTime.now().add(const Duration(hours: 24)),
              )));
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(const StartCheckout(sessionId: 'test-session')),
        expect: () => [
          CheckoutLoading(),
          isA<CheckoutInProgress>(),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [CheckoutLoading, CheckoutError] when fails',
        build: () {
          when(() => mockResumeUseCase(any()))
              .thenAnswer((_) async => Left(ServerFailure('Session not found')));
          return checkoutBloc;
        },
        act: (bloc) => bloc.add(const StartCheckout(sessionId: 'test-session')),
        expect: () => [
          CheckoutLoading(),
          isA<CheckoutError>(),
        ],
      );
    });

    group('SaveStepData', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'emits [CheckoutLoading, CheckoutStepSaved] when successful',
        build: () {
          final session = CheckoutSessionModel(
            sessionId: 'test-session',
            userId: 'user123',
            currentStep: CheckoutStepType.shipping,
            stepData: {
              CheckoutStepType.shipping: {'address': '123 Test St'},
            },
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
          );

          when(() => mockSaveUseCase(any()))
              .thenAnswer((_) async => const Right(true));

          // Set up the current state
          checkoutBloc.emit(CheckoutInProgress(session: session));

          return checkoutBloc;
        },
        act: (bloc) => bloc.add(SaveStepData(
          stepType: CheckoutStepType.shipping,
          data: {'address': '123 Test St'},
          securityContext: SecurityContextModel(
            sessionId: 'test-session',
            userId: 'user123',
            ipAddress: '192.168.1.1',
            userAgent: 'Test Browser',
            deviceFingerprint: 'test-fingerprint',
            riskLevel: RiskLevel.low,
            validationTimestamp: DateTime.now(),
          ),
        )),
        expect: () => [
          CheckoutLoading(),
          isA<CheckoutStepSaved>(),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [CheckoutLoading, CheckoutError] when save fails',
        build: () {
          final session = CheckoutSessionModel(
            sessionId: 'test-session',
            userId: 'user123',
            currentStep: CheckoutStepType.shipping,
            stepData: {},
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
          );

          when(() => mockSaveUseCase(any()))
              .thenAnswer((_) async => Left(CacheFailure('Save failed')));

          // Set up the current state
          checkoutBloc.emit(CheckoutInProgress(session: session));

          return checkoutBloc;
        },
        act: (bloc) => bloc.add(SaveStepData(
          stepType: CheckoutStepType.shipping,
          data: {'address': '123 Test St'},
          securityContext: SecurityContextModel(
            sessionId: 'test-session',
            userId: 'user123',
            ipAddress: '192.168.1.1',
            userAgent: 'Test Browser',
            deviceFingerprint: 'test-fingerprint',
            riskLevel: RiskLevel.low,
            validationTimestamp: DateTime.now(),
          ),
        )),
        expect: () => [
          CheckoutLoading(),
          isA<CheckoutError>(),
        ],
      );
    });

    group('ValidateStep', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'emits [CheckoutLoading, CheckoutStepValid] when validation passes',
        build: () {
          final session = CheckoutSessionModel(
            sessionId: 'test-session',
            userId: 'user123',
            currentStep: CheckoutStepType.shipping,
            stepData: {
              CheckoutStepType.shipping: {'address': '123 Test St'},
            },
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
          );

          when(() => mockValidateUseCase(any()))
              .thenAnswer((_) async => Right(CheckoutValidationResult(
                isValid: true,
                errors: [],
                warnings: [],
                validatedAt: DateTime.now(),
              )));

          // Set up the current state
          checkoutBloc.emit(CheckoutInProgress(session: session));

          return checkoutBloc;
        },
        act: (bloc) => bloc.add(const ValidateStep(stepType: CheckoutStepType.shipping)),
        expect: () => [
          CheckoutLoading(),
          isA<CheckoutStepValid>(),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [CheckoutLoading, CheckoutStepInvalid] when validation fails',
        build: () {
          final session = CheckoutSessionModel(
            sessionId: 'test-session',
            userId: 'user123',
            currentStep: CheckoutStepType.shipping,
            stepData: {},
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
          );

          when(() => mockValidateUseCase(any()))
              .thenAnswer((_) async => Right(CheckoutValidationResult(
                isValid: false,
                errors: ['Address is required'],
                warnings: [],
                validatedAt: DateTime.now(),
              )));

          // Set up the current state
          checkoutBloc.emit(CheckoutInProgress(session: session));

          return checkoutBloc;
        },
        act: (bloc) => bloc.add(const ValidateStep(stepType: CheckoutStepType.shipping)),
        expect: () => [
          CheckoutLoading(),
          isA<CheckoutStepInvalid>(),
        ],
      );
    });

    group('CompleteCheckout', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'emits [CheckoutLoading, CheckoutCompleted] when successful',
        build: () {
          final session = CheckoutSessionModel(
            sessionId: 'test-session',
            userId: 'user123',
            currentStep: CheckoutStepType.confirmation,
            stepData: {
              CheckoutStepType.shipping: {'address': '123 Test St'},
              CheckoutStepType.payment: {'method': 'credit_card'},
            },
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
          );

          when(() => mockCompleteUseCase(any()))
              .thenAnswer((_) async => Right('order-123'));

          // Set up the current state
          checkoutBloc.emit(CheckoutInProgress(session: session));

          return checkoutBloc;
        },
        act: (bloc) => bloc.add(const CompleteCheckout()),
        expect: () => [
          CheckoutLoading(),
          isA<CheckoutCompleted>(),
        ],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'emits [CheckoutLoading, CheckoutError] when completion fails',
        build: () {
          final session = CheckoutSessionModel(
            sessionId: 'test-session',
            userId: 'user123',
            currentStep: CheckoutStepType.confirmation,
            stepData: {},
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
          );

          when(() => mockCompleteUseCase(any()))
              .thenAnswer((_) async => Left(PaymentFailure('Payment failed')));

          // Set up the current state
          checkoutBloc.emit(CheckoutInProgress(session: session));

          return checkoutBloc;
        },
        act: (bloc) => bloc.add(const CompleteCheckout()),
        expect: () => [
          CheckoutLoading(),
          isA<CheckoutError>(),
        ],
      );
    });

    group('AutoSaveStepData', () {
      blocTest<CheckoutBloc, CheckoutState>(
        'should save data without emitting loading state',
        build: () {
          final session = CheckoutSessionModel(
            sessionId: 'test-session',
            userId: 'user123',
            currentStep: CheckoutStepType.shipping,
            stepData: {},
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
          );

          when(() => mockSaveUseCase(any()))
              .thenAnswer((_) async => const Right(true));

          // Set up the current state
          checkoutBloc.emit(CheckoutInProgress(session: session));

          return checkoutBloc;
        },
        act: (bloc) => bloc.add(AutoSaveStepData(
          stepType: CheckoutStepType.shipping,
          data: {'address': '123 Test St'},
          securityContext: SecurityContextModel(
            sessionId: 'test-session',
            userId: 'user123',
            ipAddress: '192.168.1.1',
            userAgent: 'Test Browser',
            deviceFingerprint: 'test-fingerprint',
            riskLevel: RiskLevel.low,
            validationTimestamp: DateTime.now(),
          ),
        )),
        expect: () => [],
      );

      blocTest<CheckoutBloc, CheckoutState>(
        'should handle auto-save failures gracefully',
        build: () {
          final session = CheckoutSessionModel(
            sessionId: 'test-session',
            userId: 'user123',
            currentStep: CheckoutStepType.shipping,
            stepData: {},
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
          );

          when(() => mockSaveUseCase(any()))
              .thenAnswer((_) async => Left(CacheFailure('Auto-save failed')));

          // Set up the current state
          checkoutBloc.emit(CheckoutInProgress(session: session));

          return checkoutBloc;
        },
        act: (bloc) => bloc.add(AutoSaveStepData(
          stepType: CheckoutStepType.shipping,
          data: {'address': '123 Test St'},
          securityContext: SecurityContextModel(
            sessionId: 'test-session',
            userId: 'user123',
            ipAddress: '192.168.1.1',
            userAgent: 'Test Browser',
            deviceFingerprint: 'test-fingerprint',
            riskLevel: RiskLevel.low,
            validationTimestamp: DateTime.now(),
          ),
        )),
        expect: () => [],
      );
    });
  });
}