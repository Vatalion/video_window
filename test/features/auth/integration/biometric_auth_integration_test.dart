import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/domain/models/user_model.dart';
import 'package:video_window/features/auth/domain/models/biometric_models.dart';
import 'package:video_window/features/auth/domain/repositories/auth_repository.dart';
import 'package:video_window/features/auth/data/services/biometric_auth_service.dart';
import 'package:video_window/features/auth/data/services/biometric_api_service.dart';
import 'package:video_window/features/auth/data/services/biometric_auth_middleware.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_event.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBiometricAuthService extends Mock implements BiometricAuthService {}

class MockBiometricApiService extends Mock implements BiometricApiService {}

class MockBiometricAuthMiddleware extends Mock implements BiometricAuthMiddleware {}

void main() {
  group('Biometric Authentication Integration Tests', () {
    late AuthRepository mockAuthRepository;
    late BiometricAuthService mockBiometricAuthService;
    late BiometricApiService mockBiometricApiService;
    late BiometricAuthMiddleware mockBiometricAuthMiddleware;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockBiometricAuthService = MockBiometricAuthService();
      mockBiometricApiService = MockBiometricApiService();
      mockBiometricAuthMiddleware = MockBiometricAuthMiddleware();

      authBloc = AuthBloc(
        authRepository: mockAuthRepository,
        socialAuthManager: MockSocialAuthManager(),
        biometricAuthService: mockBiometricAuthService,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    group('End-to-End Biometric Setup Flow', () {
      testWidgets('Should successfully setup biometric authentication', (tester) async {
        // Arrange
        when(() => mockBiometricAuthService.checkBiometricCapability())
            .thenAnswer((_) async => BiometricDeviceCapability(
                  type: BiometricType.faceId,
                  isAvailable: true,
                  status: BiometricAuthStatus.available,
                ));

        when(() => mockBiometricAuthService.enableBiometricAuth())
            .thenAnswer((_) async => true);

        when(() => mockBiometricAuthService.getBiometricPreferences())
            .thenAnswer((_) async => BiometricPreferences(
                  isEnabled: true,
                  preferredBiometricType: BiometricType.faceId,
                  lastSuccessfulAuth: DateTime.now(),
                ));

        // Act
        authBloc.add(CheckBiometricCapabilityEvent());
        await tester.pumpAndSettle();

        authBloc.add(SetupBiometricAuthEvent());
        await tester.pumpAndSettle();

        authBloc.add(GetBiometricPreferencesEvent());
        await tester.pumpAndSettle();

        // Assert
        expect(authBloc.state, isA<BiometricPreferencesLoaded>());
        final state = authBloc.state as BiometricPreferencesLoaded;
        expect(state.isEnabled, isTrue);
        expect(state.biometricType, equals(BiometricType.faceId.name));
      });

      testWidgets('Should handle biometric setup failure', (tester) async {
        // Arrange
        when(() => mockBiometricAuthService.checkBiometricCapability())
            .thenAnswer((_) async => BiometricDeviceCapability(
                  type: BiometricType.none,
                  isAvailable: false,
                  status: BiometricAuthStatus.notAvailable,
                  errorMessage: 'Biometrics not available',
                ));

        // Act
        authBloc.add(CheckBiometricCapabilityEvent());
        await tester.pumpAndSettle();

        authBloc.add(SetupBiometricAuthEvent());
        await tester.pumpAndSettle();

        // Assert
        expect(authBloc.state, isA<BiometricAuthSetupComplete>());
        final state = authBloc.state as BiometricAuthSetupComplete;
        expect(state.success, isFalse);
        expect(state.errorMessage, contains('not available'));
      });
    });

    group('End-to-End Biometric Login Flow', () {
      testWidgets('Should successfully authenticate with biometrics', (tester) async {
        // Arrange
        when(() => mockBiometricAuthService.getBiometricPreferences())
            .thenAnswer((_) async => BiometricPreferences(
                  isEnabled: true,
                  preferredBiometricType: BiometricType.faceId,
                ));

        when(() => mockBiometricAuthService.authenticate(reason: any(named: 'reason')))
            .thenAnswer((_) async => BiometricAuthResult.success(
                  biometricType: BiometricType.faceId,
                ));

        when(() => mockBiometricAuthService.getBiometricPreferences())
            .thenAnswer((_) async => BiometricPreferences(
                  isEnabled: true,
                  preferredBiometricType: BiometricType.faceId,
                  lastSuccessfulAuth: DateTime.now(),
                  failedAttempts: 0,
                ));

        // Act
        authBloc.add(BiometricLoginEvent());
        await tester.pumpAndSettle();

        // Assert
        expect(authBloc.state, isA<BiometricAuthSuccess>());
        final state = authBloc.state as BiometricAuthSuccess;
        expect(state.biometricType, equals(BiometricType.faceId.name));
      });

      testWidgets('Should handle biometric authentication failure', (tester) async {
        // Arrange
        when(() => mockBiometricAuthService.getBiometricPreferences())
            .thenAnswer((_) async => BiometricPreferences(
                  isEnabled: true,
                  preferredBiometricType: BiometricType.faceId,
                  failedAttempts: 2,
                ));

        when(() => mockBiometricAuthService.authenticate(reason: any(named: 'reason')))
            .thenAnswer((_) async => BiometricAuthResult.failure(
                  errorMessage: 'Biometric authentication failed',
                  biometricType: BiometricType.faceId,
                ));

        // Act
        authBloc.add(BiometricLoginEvent());
        await tester.pumpAndSettle();

        // Assert
        expect(authBloc.state, isA<BiometricAuthFailed>());
        final state = authBloc.state as BiometricAuthFailed;
        expect(state.reason, contains('failed'));
        expect(state.remainingAttempts, equals(3)); // 2 failed + 1 current = 3, max is 5
      });
    });

    group('Biometric Preference Management Flow', () {
      testWidgets('Should toggle biometric authentication on and off', (tester) async {
        // Arrange - Enable
        when(() => mockBiometricAuthService.enableBiometricAuth())
            .thenAnswer((_) async => true);

        when(() => mockBiometricAuthService.getBiometricPreferences())
            .thenAnswer((_) async => BiometricPreferences(
                  isEnabled: true,
                  preferredBiometricType: BiometricType.faceId,
                ));

        // Act - Enable
        authBloc.add(ToggleBiometricAuthEvent(enable: true));
        await tester.pumpAndSettle();

        // Assert - Enabled
        expect(authBloc.state, isA<BiometricPreferencesLoaded>());
        var state = authBloc.state as BiometricPreferencesLoaded;
        expect(state.isEnabled, isTrue);

        // Arrange - Disable
        when(() => mockBiometricAuthService.disableBiometricAuth())
            .thenAnswer((_) async => true);

        when(() => mockBiometricAuthService.getBiometricPreferences())
            .thenAnswer((_) async => BiometricPreferences(
                  isEnabled: false,
                  preferredBiometricType: BiometricType.none,
                ));

        // Act - Disable
        authBloc.add(ToggleBiometricAuthEvent(enable: false));
        await tester.pumpAndSettle();

        // Assert - Disabled
        expect(authBloc.state, isA<BiometricPreferencesLoaded>());
        state = authBloc.state as BiometricPreferencesLoaded;
        expect(state.isEnabled, isFalse);
      });
    });

    group('Biometric Error Handling Flow', () {
      testWidgets('Should handle biometric lockout scenario', (tester) async {
        // Arrange
        when(() => mockBiometricAuthService.getBiometricPreferences())
            .thenAnswer((_) async => BiometricPreferences(
                  isEnabled: true,
                  preferredBiometricType: BiometricType.faceId,
                  failedAttempts: 5,
                  lockoutUntil: DateTime.now().add(const Duration(minutes: 5)),
                ));

        when(() => mockBiometricAuthService.authenticate(reason: any(named: 'reason')))
            .thenAnswer((_) async => BiometricAuthResult.failure(
                  errorMessage: 'Biometric authentication is temporarily locked',
                  biometricType: BiometricType.faceId,
                ));

        // Act
        authBloc.add(BiometricLoginEvent());
        await tester.pumpAndSettle();

        // Assert
        expect(authBloc.state, isA<BiometricAuthFailed>());
        final state = authBloc.state as BiometricAuthFailed;
        expect(state.reason, contains('locked'));
        expect(state.remainingAttempts, equals(0));
      });

      testWidgets('Should handle biometric capability check errors', (tester) async {
        // Arrange
        when(() => mockBiometricAuthService.checkBiometricCapability())
            .thenThrow(Exception('Service unavailable'));

        // Act
        authBloc.add(CheckBiometricCapabilityEvent());
        await tester.pumpAndSettle();

        // Assert
        expect(authBloc.state, isA<AuthErrorState>());
        final state = authBloc.state as AuthErrorState;
        expect(state.message, contains('check biometric capability'));
      });
    });

    group('Biometric Integration with Auth System', () {
      testWidgets('Should integrate biometric auth with regular auth flow', (tester) async {
        // Arrange - User registration
        final testUser = UserModel(
          id: 'test-user-id',
          email: 'test@example.com',
          isEmailVerified: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => mockAuthRepository.registerWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              ageVerified: any(named: 'ageVerified'),
              consentData: any(named: 'consentData'),
            )).thenAnswer((_) async => testUser);

        when(() => mockAuthRepository.recordLoginAttempt(
              email: any(named: 'email'),
              phone: any(named: 'phone'),
              ipAddress: any(named: 'ipAddress'),
              userAgent: any(named: 'userAgent'),
              wasSuccessful: any(named: 'wasSuccessful'),
              userId: any(named: 'userId'),
              failureReason: any(named: 'failureReason'),
            )).thenAnswer((_) async {});

        // Act - Register user
        authBloc.add(RegisterWithEmailEvent(
          email: 'test@example.com',
          password: 'password123',
          ageVerified: true,
          consentData: {},
        ));
        await tester.pumpAndSettle();

        // Assert - User registered
        expect(authBloc.state, isA<AuthenticatedState>());
        final authState = authBloc.state as AuthenticatedState;
        expect(authState.user.id, equals(testUser.id));

        // Arrange - Setup biometrics
        when(() => mockBiometricAuthService.checkBiometricCapability())
            .thenAnswer((_) async => BiometricDeviceCapability(
                  type: BiometricType.faceId,
                  isAvailable: true,
                  status: BiometricAuthStatus.available,
                ));

        when(() => mockBiometricAuthService.enableBiometricAuth())
            .thenAnswer((_) async => true);

        // Act - Setup biometrics
        authBloc.add(CheckBiometricCapabilityEvent());
        await tester.pumpAndSettle();

        authBloc.add(SetupBiometricAuthEvent());
        await tester.pumpAndSettle();

        // Assert - Biometrics setup complete
        expect(authBloc.state, isA<BiometricAuthSetupComplete>());
        final biometricState = authBloc.state as BiometricAuthSetupComplete;
        expect(biometricState.success, isTrue);
      });
    });
  });
}

// Mock SocialAuthManager for testing
class MockSocialAuthManager extends Mock {
  Future<SocialAuthResult> signInWithProvider(String provider) async {
    return SocialAuthResult(
      isSuccess: true,
      user: UserModel(
        id: 'test-user-id',
        email: 'test@example.com',
        isEmailVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      socialAccount: null,
      isNewUser: false,
    );
  }

  Future<bool> unlinkSocialAccount({
    required String userId,
    required String socialAccountId,
  }) async {
    return true;
  }

  Future<List<SocialAccountModel>> getLinkedSocialAccounts(String userId) async {
    return [];
  }
}