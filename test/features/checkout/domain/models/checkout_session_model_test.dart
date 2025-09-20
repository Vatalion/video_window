import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/checkout/domain/models/checkout_session_model.dart';

void main() {
  group('CheckoutSessionModel', () {
    group('fromJson', () {
      test('should create model from valid JSON', () {
        // Arrange
        final json = {
          'sessionId': 'test-session-id',
          'userId': 'user123',
          'currentStep': 'shipping',
          'stepData': {
            'shipping': {'address': '123 Test St'},
            'payment': {'method': 'credit_card'},
          },
          'createdAt': '2023-01-01T12:00:00.000Z',
          'expiresAt': '2023-01-02T12:00:00.000Z',
          'lastActivity': '2023-01-01T12:30:00.000Z',
          'status': 'active',
          'isGuest': false,
          'abandonmentReason': null,
        };

        // Act
        final model = CheckoutSessionModel.fromJson(json);

        // Assert
        expect(model.sessionId, equals('test-session-id'));
        expect(model.userId, equals('user123'));
        expect(model.currentStep, equals(CheckoutStepType.shipping));
        expect(model.stepData[CheckoutStepType.shipping]['address'], equals('123 Test St'));
        expect(model.stepData[CheckoutStepType.payment]['method'], equals('credit_card'));
        expect(model.createdAt, equals(DateTime.parse('2023-01-01T12:00:00.000Z')));
        expect(model.expiresAt, equals(DateTime.parse('2023-01-02T12:00:00.000Z')));
        expect(model.status, equals(SessionStatus.active));
        expect(model.isGuest, isFalse);
        expect(model.abandonmentReason, isNull);
      });

      test('should handle optional fields', () {
        // Arrange
        final json = {
          'sessionId': 'test-session-id',
          'userId': 'user123',
          'currentStep': 'shipping',
          'stepData': {},
          'createdAt': '2023-01-01T12:00:00.000Z',
          'expiresAt': '2023-01-02T12:00:00.000Z',
        };

        // Act
        final model = CheckoutSessionModel.fromJson(json);

        // Assert
        expect(model.sessionId, equals('test-session-id'));
        expect(model.lastActivity, isNull);
        expect(model.status, equals(SessionStatus.active));
        expect(model.isGuest, isFalse);
        expect(model.abandonmentReason, isNull);
      });

      test('should throw exception for invalid JSON', () {
        // Arrange
        final json = {
          'sessionId': 'test-session-id',
          // Missing required fields
        };

        // Act & Assert
        expect(
          () => CheckoutSessionModel.fromJson(json),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('toJson', () {
      test('should convert model to JSON', () {
        // Arrange
        final model = CheckoutSessionModel(
          sessionId: 'test-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {
            CheckoutStepType.shipping: {'address': '123 Test St'},
          },
          createdAt: DateTime.parse('2023-01-01T12:00:00.000Z'),
          expiresAt: DateTime.parse('2023-01-02T12:00:00.000Z'),
          lastActivity: DateTime.parse('2023-01-01T12:30:00.000Z'),
          status: SessionStatus.active,
          isGuest: false,
          abandonmentReason: null,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['sessionId'], equals('test-session-id'));
        expect(json['userId'], equals('user123'));
        expect(json['currentStep'], equals('shipping'));
        expect(json['stepData']['shipping']['address'], equals('123 Test St'));
        expect(json['createdAt'], equals('2023-01-01T12:00:00.000Z'));
        expect(json['expiresAt'], equals('2023-01-02T12:00:00.000Z'));
        expect(json['lastActivity'], equals('2023-01-01T12:30:00.000Z'));
        expect(json['status'], equals('active'));
        expect(json['isGuest'], isFalse);
        expect(json['abandonmentReason'], isNull);
      });
    });

    group('isValid', () {
      test('should return true for valid session', () {
        // Arrange
        final model = CheckoutSessionModel(
          sessionId: 'test-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        // Act & Assert
        expect(model.isValid, isTrue);
      });

      test('should return false for expired session', () {
        // Arrange
        final model = CheckoutSessionModel(
          sessionId: 'expired-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        // Act & Assert
        expect(model.isValid, isFalse);
      });
    });

    group('isExpired', () {
      test('should return true for expired session', () {
        // Arrange
        final model = CheckoutSessionModel(
          sessionId: 'expired-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        // Act & Assert
        expect(model.isExpired, isTrue);
      });

      test('should return false for active session', () {
        // Arrange
        final model = CheckoutSessionModel(
          sessionId: 'active-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        // Act & Assert
        expect(model.isExpired, isFalse);
      });
    });

    group('isAbandoned', () {
      test('should return true for abandoned session', () {
        // Arrange
        final model = CheckoutSessionModel(
          sessionId: 'abandoned-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().add(const Duration(hours: 22)),
          lastActivity: DateTime.now().subtract(const Duration(minutes: 31)),
          status: SessionStatus.abandoned,
        );

        // Act & Assert
        expect(model.isAbandoned, isTrue);
      });

      test('should return false for active session', () {
        // Arrange
        final model = CheckoutSessionModel(
          sessionId: 'active-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
          status: SessionStatus.active,
        );

        // Act & Assert
        expect(model.isAbandoned, isFalse);
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        final model1 = CheckoutSessionModel(
          sessionId: 'test-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.parse('2023-01-01T12:00:00.000Z'),
          expiresAt: DateTime.parse('2023-01-02T12:00:00.000Z'),
        );

        final model2 = CheckoutSessionModel(
          sessionId: 'test-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.parse('2023-01-01T12:00:00.000Z'),
          expiresAt: DateTime.parse('2023-01-02T12:00:00.000Z'),
        );

        // Act & Assert
        expect(model1, equals(model2));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final model1 = CheckoutSessionModel(
          sessionId: 'session-1',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.parse('2023-01-01T12:00:00.000Z'),
          expiresAt: DateTime.parse('2023-01-02T12:00:00.000Z'),
        );

        final model2 = CheckoutSessionModel(
          sessionId: 'session-2',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.parse('2023-01-01T12:00:00.000Z'),
          expiresAt: DateTime.parse('2023-01-02T12:00:00.000Z'),
        );

        // Act & Assert
        expect(model1, isNot(equals(model2)));
      });
    });

    group('hashCode', () {
      test('should generate consistent hashCode', () {
        // Arrange
        final model = CheckoutSessionModel(
          sessionId: 'test-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.parse('2023-01-01T12:00:00.000Z'),
          expiresAt: DateTime.parse('2023-01-02T12:00:00.000Z'),
        );

        // Act & Assert
        expect(model.hashCode, isNotNull);
        expect(model.hashCode, equals(model.hashCode)); // Consistent
      });
    });
  });
}