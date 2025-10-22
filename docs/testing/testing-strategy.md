# Testing Strategy for Video Window

**Effective Date:** 2025-10-14
**Target Framework:** Flutter 3.35.0+, Serverpod 2.9.x
**Coverage Target:** 80%+ overall, 90%+ for critical business logic

## Overview

This document outlines the comprehensive testing strategy for the Video Window Flutter application. The strategy ensures high-quality code, reliable features, and excellent user experience through systematic testing at all levels.

## Testing Architecture

### Testing Pyramid Distribution

| Test Type | Percentage | Focus Areas | Tools |
|-----------|------------|--------------|-------|
| **Unit Tests** | 70% | Business logic, BLoC, Use Cases, Models | flutter_test, mocktail |
| **Integration Tests** | 20% | API endpoints, database, payment flows | integration_test, test_containers |
| **E2E Tests** | 10% | Critical user journeys, cross-platform | integration_test, device_farm |

### Test Categories

#### 1. Unit Tests (70%)
- **BLoC State Management** - Authentication, feed, auction flows
- **Use Cases** - Business logic and domain rules
- **Data Models** - Serialization/deserialization, validation
- **Repository Implementations** - Data source interactions
- **Utility Functions** - Helper methods and calculations

#### 2. Integration Tests (20%)
- **API Endpoints** - Serverpod integration with real database
- **Payment Flows** - Stripe checkout simulation
- **Video Processing** - Upload, transcoding, playback
- **Real-time Features** - Auction timers, WebSocket connections
- **Authentication Workflows** - Complete sign-up/sign-in flows

#### 3. End-to-End Tests (10%)
- **Critical User Journeys** - Discovery → Purchase → Delivery
- **Cross-Platform Testing** - iOS, Android, Web compatibility
- **Performance Testing** - Load testing, memory usage
- **Accessibility Testing** - Screen readers, navigation

## Testing Framework Setup

### Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # Testing frameworks
  integration_test:
    sdk: flutter
  mocktail: ^1.0.3
  golden_toolkit: ^0.15.0
  bloc_test: ^9.1.7

  # Testing utilities
  fake_async: ^1.3.1
  clock: ^1.1.1
  network_image_mock: ^2.1.1

  # Performance testing
  test_api: ^0.7.0
  flutter_driver:
    sdk: flutter

  # Code coverage
  coverage: ^1.8.0

  # Static analysis
  very_good_analysis: ^5.1.0
```

### Test Directory Structure

```
test/
├── unit/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── bloc/
│   │   │   ├── data/
│   │   │   └── domain/
│   │   ├── feed/
│   │   ├── auction/
│   │   └── payment/
│   ├── shared/
│   │   ├── utils/
│   │   ├── widgets/
│   │   └── models/
│   └── helpers/
│       ├── mock_helpers.dart
│       ├── test_data.dart
│       └── fixtures.dart
├── integration/
│   ├── features/
│   │   ├── auth_flow_test.dart
│   │   ├── auction_flow_test.dart
│   │   ├── payment_flow_test.dart
│   │   └── video_playback_test.dart
│   ├── api/
│   │   ├── auth_endpoint_test.dart
│   │   ├── auction_endpoint_test.dart
│   │   └── payment_endpoint_test.dart
│   └── helpers/
│       ├── integration_test_helpers.dart
│       └── test_server.dart
├── widget/
│   ├── auth/
│   │   ├── login_page_test.dart
│   │   └── register_page_test.dart
│   ├── feed/
│   │   ├── video_feed_test.dart
│   │   └── story_page_test.dart
│   └── common/
│       ├── loading_widget_test.dart
│       └── error_widget_test.dart
├── golden/
│   ├── themes/
│   ├── components/
│   └── screens/
└── performance/
    ├── memory_test.dart
    ├── startup_time_test.dart
    └── scroll_performance_test.dart
```

## Unit Testing Implementation

### BLoC Testing Strategy

```dart
// test/unit/features/auth/bloc/auth_bloc_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:video_window/features/auth/domain/entities/user_entity.dart';
import 'package:video_window/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:video_window/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(
      signInWithEmail: SignInWithEmailUseCase(repository: mockAuthRepository),
      signUpWithEmail: SignUpWithEmailUseCase(repository: mockAuthRepository),
      signInWithSocial: SignInWithSocialUseCase(repository: mockAuthRepository),
      signOut: SignOutUseCase(repository: mockAuthRepository),
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc - Authentication Flow', () {
    const testUser = UserEntity(
      id: '1',
      email: 'test@example.com',
      displayName: 'Test User',
      isEmailVerified: true,
      isMaker: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      providers: ['email'],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when sign in succeeds',
      setUp: () {
        when(() => mockAuthRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => testUser);
      },
      build: () => authBloc,
      act: (bloc) => bloc.add(const SignInEmailRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        AuthLoading(),
        Authenticated(user: testUser),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when sign in fails',
      setUp: () {
        when(() => mockAuthRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(AuthException('Invalid credentials'));
      },
      build: () => authBloc,
      act: (bloc) => bloc.add(const SignInEmailRequested(
        email: 'test@example.com',
        password: 'wrongpassword',
      )),
      expect: () => [
        AuthLoading(),
        const AuthError(message: 'Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when sign out succeeds',
      setUp: () {
        when(() => mockAuthRepository.signOut())
            .thenAnswer((_) async {});
      },
      build: () => authBloc,
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );
  });
}
```

### Use Case Testing

```dart
// test/unit/features/auth/domain/usecases/sign_in_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/domain/entities/user_entity.dart';
import 'package:video_window/features/auth/domain/repositories/auth_repository.dart';
import 'package:video_window/features/auth/domain/usecases/sign_in_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithEmailUseCase(repository: mockRepository);
  });

  const testUser = UserEntity(
    id: '1',
    email: 'test@example.com',
    displayName: 'Test User',
    isEmailVerified: true,
    isMaker: false,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    providers: ['email'],
  );

  group('SignInWithEmailUseCase', () {
    test('should return user when sign in succeeds', () async {
      // Arrange
      when(() => mockRepository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await useCase(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result, equals(testUser));
      verify(() => mockRepository.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('should throw AuthException when credentials are invalid', () async {
      // Arrange
      when(() => mockRepository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(AuthException('Invalid credentials'));

      // Act
      final call = useCase.call;

      // Assert
      expect(
        () => call(email: 'test@example.com', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

### Repository Testing

```dart
// test/unit/features/auth/data/repositories/auth_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:video_window/features_auth/data/datasources/auth_remote_data_source.dart';
import 'package:video_window/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:video_window/features_auth/data/models/user_model.dart';
import 'package:video_window/features/auth/domain/entities/user_entity.dart';

class MockRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('AuthRepositoryImpl', () {
    const testUserModel = UserModel(
      id: '1',
      email: 'test@example.com',
      displayName: 'Test User',
      isEmailVerified: true,
      isMaker: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      providers: ['email'],
    );

    test('should cache user when sign in succeeds', () async {
      // Arrange
      when(() => mockRemoteDataSource.signInWithEmail(any())).thenAnswer((_) async => testUserModel);
      when(() => mockLocalDataSource.cacheUser(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result, isA<UserEntity>());
      verify(() => mockLocalDataSource.cacheUser(testUserModel)).called(1);
    });

    test('should return cached user when available', () async {
      // Arrange
      when(() => mockLocalDataSource.getCachedUser()).thenAnswer((_) async => testUserModel);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, equals(testUserModel.toEntity()));
      verify(() => mockLocalDataSource.getCachedUser()).called(1);
      verifyNever(() => mockRemoteDataSource.signInWithEmail(any()));
    });
  });
}
```

### Model Testing

```dart
// test/unit/features/auth/data/models/user_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    const testJson = {
      'id': '1',
      'email': 'test@example.com',
      'displayName': 'Test User',
      'photoUrl': 'https://example.com/photo.jpg',
      'isEmailVerified': true,
      'isMaker': false,
      'createdAt': '2025-01-01T00:00:00.000Z',
      'updatedAt': '2025-01-01T00:00:00.000Z',
      'providers': ['email'],
      'metadata': {'key': 'value'},
    };

    const testUserModel = UserModel(
      id: '1',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      isEmailVerified: true,
      isMaker: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      providers: ['email'],
      metadata: {'key': 'value'},
    );

    test('should deserialize from JSON correctly', () {
      // Act
      final result = UserModel.fromJson(testJson);

      // Assert
      expect(result, equals(testUserModel));
    });

    test('should serialize to JSON correctly', () {
      // Act
      final result = testUserModel.toJson();

      // Assert
      expect(result, equals(testJson));
    });

    test('should convert to entity correctly', () {
      // Act
      final entity = testUserModel.toEntity();

      // Assert
      expect(entity.id, equals(testUserModel.id));
      expect(entity.email, equals(testUserModel.email));
      expect(entity.displayName, equals(testUserModel.displayName));
    });

    test('should create from entity correctly', () {
      // Arrange
      final entity = testUserModel.toEntity();

      // Act
      final result = UserModel.fromEntity(entity);

      // Assert
      expect(result, equals(testUserModel));
    });
  });
}
```

## Widget Testing Implementation

### Page Widget Testing

```dart
// test/widget/auth/login_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:video_window/features/auth/presentation/pages/login_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginPage(),
      ),
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('displays login form correctly', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue to Craft Marketplace'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('shows loading indicator when authentication is in progress', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when authentication fails', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(
        const AuthError(message: 'Invalid credentials'),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('enables sign in button when form is valid', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid email and password
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.pump();

      // Assert
      final signInButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(signInButton.onPressed, isNotNull);
    });

    testWidgets('disables sign in button when form is invalid', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid email
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.pump();

      // Assert
      final signInButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(signInButton.onPressed, isNull);
    });

    testWidgets('calls sign in when valid form is submitted', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid credentials and submit
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert
      verify(() => mockAuthBloc.add(const SignInEmailRequested(
        email: 'test@example.com',
        password: 'password123',
      ))).called(1);
    });
  });
}
```

### Custom Widget Testing

```dart
// test/widget/common/video_player_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:video_window/features/feed/presentation/widgets/video_player_widget.dart';

void main() {
  group('VideoPlayerWidget', () {
    const testVideoUrl = 'https://example.com/video.mp4';
    const testThumbnailUrl = 'https://example.com/thumbnail.jpg';

    testWidgets('displays thumbnail when video is not playing', (tester) async {
      // Act
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoPlayerWidget(
                videoUrl: testVideoUrl,
                thumbnailUrl: testThumbnailUrl,
                isPlaying: false,
                onPlayPressed: () {},
              ),
            ),
          ),
        );
      });

      // Assert
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows video player when video is playing', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(
              videoUrl: testVideoUrl,
              thumbnailUrl: testThumbnailUrl,
              isPlaying: true,
              onPlayPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('calls onPlayPressed when play button is tapped', (tester) async {
      // Arrange
      var playPressed = false;

      // Act
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoPlayerWidget(
                videoUrl: testVideoUrl,
                thumbnailUrl: testThumbnailUrl,
                isPlaying: false,
                onPlayPressed: () => playPressed = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();
      });

      // Assert
      expect(playPressed, isTrue);
    });
  });
}
```

## Integration Testing Implementation

### API Integration Testing

```dart
// test/integration/api/auth_endpoint_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_test_serverpod/serverpod_test_serverpod.dart';
import 'package:video_window_server/generated/endpoints.dart';
import 'package:video_window_server/generated/protocol.dart';

void main() {
  late ServerpodTestServerpod testServerpod;

  setUpAll(() async {
    testServerpod = ServerpodTestServerpod(
      runServer: true,
      port: 8081,
    );
    await testServerpod.start();
  });

  tearDownAll(() async {
    await testServerpod.stop();
  });

  group('Auth Endpoint Integration Tests', () {
    late Session session;

    setUp(() {
      session = testServerpod.createSession();
    });

    test('should sign up new user successfully', () async {
      // Arrange
      final request = EmailSignUpRequest(
        email: 'integrationtest@example.com',
        password: 'password123',
        displayName: 'Integration Test User',
        isMaker: false,
      );

      // Act
      final user = await session.auth.signUpWithEmail(request);

      // Assert
      expect(user.email, equals(request.email));
      expect(user.displayName, equals(request.displayName));
      expect(user.isEmailVerified, isFalse);
      expect(user.providers, contains('email'));
    });

    test('should sign in existing user successfully', () async {
      // Arrange
      final signUpRequest = EmailSignUpRequest(
        email: 'signinintegration@example.com',
        password: 'password123',
        displayName: 'Sign In Test User',
        isMaker: false,
      );

      await session.auth.signUpWithEmail(signUpRequest);

      final signInRequest = EmailSignInRequest(
        email: 'signinintegration@example.com',
        password: 'password123',
      );

      // Act
      final user = await session.auth.signInWithEmail(signInRequest);

      // Assert
      expect(user.email, equals(signInRequest.email));
      expect(user.isAuthenticated, isTrue);
    });

    test('should fail sign in with invalid credentials', () async {
      // Arrange
      final request = EmailSignInRequest(
        email: 'nonexistent@example.com',
        password: 'wrongpassword',
      );

      // Act & Assert
      expect(
        () => session.auth.signInWithEmail(request),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('should create user session after successful sign in', () async {
      // Arrange
      final signUpRequest = EmailSignUpRequest(
        email: 'sessiontest@example.com',
        password: 'password123',
        displayName: 'Session Test User',
        isMaker: false,
      );

      final user = await session.auth.signUpWithEmail(signUpRequest);

      // Act - Create new session to test session persistence
      final newSession = testServerpod.createSession();
      newSession.authenticatedUserId = user.id;
      await newSession.save(newSession);

      final refreshedUser = await newSession.auth.refreshSession();

      // Assert
      expect(refreshedUser.id, equals(user.id));
      expect(refreshedUser.email, equals(user.email));
    });
  });
}
```

### Payment Flow Integration Testing

```dart
// test/integration/features/payment_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/main.dart' as app;
import 'package:video_window_server/generated/endpoints.dart';
import 'package:video_window_server/generated/protocol.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Flow Integration Tests', () {
    testWidgets('complete purchase flow from discovery to payment', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'testbuyer@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Navigate to feed
      expect(find.byType(FeedPage), findsOneWidget);

      // Find and view first item
      await tester.tap(find.byType(VideoThumbnail).first);
      await tester.pumpAndSettle();

      expect(find.byType(StoryPage), findsOneWidget);

      // Make offer
      await tester.tap(find.text('I Want This'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('offer_amount_field')), '50');
      await tester.tap(find.text('Submit Offer'));
      await tester.pumpAndSettle();

      // Wait for auction to start
      await tester.pump(const Duration(seconds: 2));

      // Place bid
      await tester.enterText(find.byKey(const Key('bid_amount_field')), '55');
      await tester.tap(find.text('Place Bid'));
      await tester.pumpAndSettle();

      // Verify bid placed
      expect(find.text('Your bid: \$55'), findsOneWidget);

      // Simulate winning auction
      await tester.pump(const Duration(seconds: 5)); // Wait for auction to end
      await tester.pumpAndSettle();

      // Proceed to payment
      await tester.tap(find.text('Proceed to Payment'));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentPage), findsOneWidget);

      // Complete payment
      await tester.tap(find.text('Pay Now'));
      await tester.pumpAndSettle();

      // Verify order confirmation
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Thank you for your purchase!'), findsOneWidget);
    });

    testWidgets('handles payment failure gracefully', (tester) async {
      // Arrange - Set up mock to fail payment
      // (Implementation depends on your payment mocking strategy)

      app.main();
      await tester.pumpAndSettle();

      // Complete sign in and item selection...
      // (Simplified for brevity)

      // Attempt payment that will fail
      await tester.tap(find.text('Pay Now'));
      await tester.pumpAndSettle();

      // Verify error handling
      expect(find.text('Payment Failed'), findsOneWidget);
      expect(find.text('Please try a different payment method'), findsOneWidget);
    });
  });
}
```

## Performance Testing Implementation

### Memory and Performance Testing

```dart
// test/performance/memory_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/feed/presentation/pages/feed_page.dart';

void main() {
  group('Performance Tests', () {
    testWidgets('feed page should load within performance targets', (tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: FeedPage(),
        ),
      );

      // Record initial load time
      final initialLoadTime = stopwatch.elapsedMilliseconds;

      // Pump and settle for full render
      await tester.pumpAndSettle();

      final fullLoadTime = stopwatch.elapsedMilliseconds;

      // Assert
      expect(fullLoadTime, lessThan(2000)); // Should load within 2 seconds

      print('Initial load time: ${initialLoadTime}ms');
      print('Full load time: ${fullLoadTime}ms');
    });

    testWidgets('scrolling should maintain 60fps', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: FeedPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Scroll through feed
      final scrollFinder = find.byType(Scrollable);
      await tester.fling(scrollFinder, const Offset(0, -500), 10000);
      await tester.pumpAndSettle();

      // Assert - No frame drops should occur
      // (This would require integration with Flutter's performance profiling)
    });

    testWidgets('memory usage should remain within limits', (tester) async {
      // Arrange - Get initial memory usage
      // (This requires integration with Flutter's memory profiling tools)

      // Act - Navigate through multiple screens
      await tester.pumpWidget(
        MaterialApp(
          home: FeedPage(),
        ),
      );

      // Navigate to multiple pages
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byType(VideoThumbnail).first);
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // Assert - Memory usage should not grow significantly
      // (Implementation depends on memory monitoring strategy)
    });
  });
}
```

## Test Data and Fixtures

### Test Data Helpers

```dart
// test/unit/helpers/test_data.dart

import 'package:video_window/features/auth/domain/entities/user_entity.dart';
import 'package:video_window/features/feed/domain/entities/story_entity.dart';
import 'package:video_window/features/auction/domain/entities/auction_entity.dart';

class TestData {
  // User test data
  static const testUser = UserEntity(
    id: '1',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    isEmailVerified: true,
    isMaker: false,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    providers: ['email'],
  );

  static const testMaker = UserEntity(
    id: '2',
    email: 'maker@example.com',
    displayName: 'Test Maker',
    photoUrl: 'https://example.com/maker.jpg',
    isEmailVerified: true,
    isMaker: true,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    providers: ['email'],
  );

  // Story test data
  static const testStory = StoryEntity(
    id: '1',
    makerId: '2',
    title: 'Handmade Ceramic Vase',
    description: 'Beautiful handcrafted ceramic vase with unique glazing',
    videoUrl: 'https://example.com/video.mp4',
    thumbnailUrl: 'https://example.com/thumbnail.jpg',
    category: 'pottery',
    tags: ['ceramic', 'handmade', 'vase'],
    minimumOffer: 50.0,
    buyItNowPrice: 150.0,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  // Auction test data
  static const testAuction = AuctionEntity(
    id: '1',
    storyId: '1',
    currentBid: 75.0,
    minimumBid: 55.0,
    endTime: DateTime(2025, 1, 2),
    status: AuctionStatus.active,
    bidderCount: 3,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  // Generate test lists
  static List<UserEntity> generateUsers(int count) {
    return List.generate(count, (index) => UserEntity(
      id: index.toString(),
      email: 'user$index@example.com',
      displayName: 'User $index',
      isEmailVerified: true,
      isMaker: index % 2 == 0,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      providers: ['email'],
    ));
  }

  static List<StoryEntity> generateStories(int count, String makerId) {
    return List.generate(count, (index) => StoryEntity(
      id: index.toString(),
      makerId: makerId,
      title: 'Story $index',
      description: 'Description for story $index',
      videoUrl: 'https://example.com/video$index.mp4',
      thumbnailUrl: 'https://example.com/thumb$index.jpg',
      category: 'test',
      tags: ['test', 'story'],
      minimumOffer: 50.0 + index * 10,
      buyItNowPrice: 150.0 + index * 20,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ));
  }
}
```

### Mock Helpers

```dart
// test/unit/helpers/mock_helpers.dart

import 'package:mocktail/mocktail.dart';
import 'package:serverpod_client/serverpod_client.dart';

class MockClient extends Mock implements Client {}

void registerFallbackValues() {
  registerFallbackValue(MockClient());
  registerFallbackValue(const Duration(seconds: 1));
}

extension MockClientExtensions on MockClient {
  void setupSuccessResponse<T>(T response) {
    when(() => call<T>(
      endpointName: any(named: 'endpointName'),
      method: any(named: 'method'),
      parameters: any(named: 'parameters'),
    )).thenAnswer((_) async => response);
  }

  void setupErrorResponse(Exception error) {
    when(() => call<T>(
      endpointName: any(named: 'endpointName'),
      method: any(named: 'method'),
      parameters: any(named: 'parameters'),
    )).thenThrow(error);
  }
}
```

## Golden Testing

### Widget Golden Tests

```dart
// test/golden/components/video_thumbnail_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:video_window/features/feed/presentation/widgets/video_thumbnail.dart';

void main() {
  setUpAll(() async {
    // Enable golden testing
    await loadAppFonts();
  });

  group('VideoThumbnail Golden Tests', () {
    const testVideoUrl = 'https://example.com/video.mp4';
    const testThumbnailUrl = 'https://example.com/thumbnail.jpg';
    const testTitle = 'Handmade Ceramic Vase';
    const testMakerName = 'Artisan Potter';

    testGoldens('VideoThumbnail renders correctly in different states', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidgetBuilder(
          (widgetTester) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  VideoThumbnail(
                    videoUrl: testVideoUrl,
                    thumbnailUrl: testThumbnailUrl,
                    title: testTitle,
                    makerName: testMakerName,
                    views: 1250,
                    likes: 89,
                    onTap: () {},
                  ),
                  VideoThumbnail(
                    videoUrl: testVideoUrl,
                    thumbnailUrl: testThumbnailUrl,
                    title: testTitle,
                    makerName: testMakerName,
                    views: 1250,
                    likes: 89,
                    isLiked: true,
                    onTap: () {},
                  ),
                  VideoThumbnail(
                    videoUrl: testVideoUrl,
                    thumbnailUrl: testThumbnailUrl,
                    title: testTitle,
                    makerName: testMakerName,
                    views: 1250,
                    likes: 89,
                    isActive: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        await multiScreenGolden(
          tester,
          'video_thumbnail_states',
          devices: [
            Device.phone,
            Device.tabletPortrait,
            Device.tabletLandscape,
          ],
        );
      });
    });
  });
}
```

## Test Execution and Coverage

### Test Configuration

```yaml
# analysis_options.yaml

include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    # Test-specific rules
    - prefer_relative_imports
    - test_types_in_equals
    - test_types_in_equals_and_hash_code
    - throw_in_finally
    - unnecessary_statements
    - unnecessary_type_check
    - unrelated_type_equality_checks
    - use_build_context_synchronously
    - valid_regexps
    - void_checks
```

### Coverage Configuration

```yaml
# test/coverage_config.yaml

coverage:
  minimum: 80

  paths:
    - lib/

  exclude:
    - lib/**/*.g.dart
    - lib/**/*.freezed.dart
    - lib/main.dart

  report:
    - lcov
    - html
    - text
```

### GitHub Actions Test Workflow

```yaml
# .github/workflows/test.yml

name: Tests

on:
  push:
    branches: [ develop, main ]
  pull_request:
    branches: [ develop ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.6'

    - name: Install dependencies
      run: flutter pub get

    - name: Generate code
      run: |
        flutter packages pub run build_runner build --delete-conflicting-outputs

    - name: Run unit tests
      run: flutter test --coverage

    - name: Run integration tests
      run: |
        flutter pub global activate integration_test
        flutter drive --target=test/integration/app_test.dart

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info

    - name: Upload test reports
      uses: actions/upload-artifact@v3
      with:
        name: test-reports
        path: test/reports/
```

---

**Last Updated:** 2025-10-09
**Related Documentation:** [Implementation Examples](../architecture/implementation-examples/README.md) | [CI/CD Pipeline](../deployment/ci-cd.md) | [Performance Optimization](../architecture/performance-optimization-guide.md)