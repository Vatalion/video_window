# Testing Strategy and Implementation Guide

## Overview

This document outlines the comprehensive testing strategy for the Craft Video Marketplace Flutter application. A robust testing approach ensures high-quality code, reliable features, and excellent user experience across all supported platforms.

## Testing Philosophy

### Core Principles
1. **Test Pyramid Structure** - Unit tests > Integration tests > E2E tests
2. **Shift Left Testing** - Test early and often in the development cycle
3. **Test Coverage with Purpose** - Focus on critical business logic and user flows
4. **Automated Quality Gates** - Prevent regressions through CI/CD automation
5. **Continuous Improvement** - Regular review and enhancement of testing practices

### Quality Goals
- **Unit Test Coverage**: ≥ 80% for business logic, 100% for critical flows
- **Integration Test Coverage**: All API endpoints and major user workflows
- **E2E Test Coverage**: Critical user journeys and edge cases
- **Performance Testing**: App startup < 3s, API response < 2s
- **Accessibility Testing**: WCAG 2.1 AA compliance

## Testing Pyramid

```
    ┌─────────────────────┐
    │   E2E Tests (5%)    │  ← Critical user journeys
    └─────────────────────┘
  ┌───────────────────────────┐
  │ Integration Tests (15%)   │  ← API, database, workflows
  └───────────────────────────┘
┌─────────────────────────────────┐
│    Unit Tests (80%)             │  ← Business logic, utilities
└─────────────────────────────────┘
```

## Unit Testing Strategy

### 1. Testing Framework Setup

#### pubspec.yaml Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.7
  golden_toolkit: ^0.15.0
  fake_async: ^1.3.1
  network_image_mock: ^2.1.1
  flutter_localizations:
    sdk: flutter

  # Additional testing utilities
  test: ^1.24.3
  bloc_test: ^9.1.4
  json_serializable: ^6.7.1
  flutter_gen_runner: ^5.3.2
```

#### Test Configuration
Create `test/test_config.dart`:
```dart
/// Global test configuration and utilities.
library test_config;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

/// Global test setup.
void setUpTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock network images to prevent network calls in tests
  setUpAll(() async {
    await setUpMockNetworkImages();
  });

  // Configure test fonts
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Load test fonts for consistent rendering
    final fontLoader = FontLoader('Roboto');
    fontLoader.addFont(rootBundle.load('fonts/Roboto-Regular.ttf'));
    await fontLoader.load();
  });

  // Common test setup
  setUp(() {
    // Reset any global state before each test
  });

  tearDown(() {
    // Clean up after each test
  });
}

/// Custom test wrapper for common test setup.
void mainTest(String description, Future<void> Function() testBody) {
  group(description, () {
    setUpAll(setUpTestEnvironment);
    test(description, testBody);
  });
}
```

### 2. Unit Testing Best Practices

#### Test File Structure
```
test/
├── unit/
│   ├── core/
│   │   ├── data/
│   │   ├── domain/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── video/
│   │   └── auction/
│   └── shared/
│       ├── widgets/
│       └── utils/
├── integration/
├── widget/
└── e2e/
```

#### Test Naming Conventions
```dart
// Good test naming
group('UserRegistrationService', () {
  group('registerUser', () {
    test('should create user when valid credentials provided', () async {
      // Test implementation
    });

    test('should throw ValidationException when email is invalid', () async {
      // Test implementation
    });

    test('should throw DuplicateUserException when email already exists', () async {
      // Test implementation
    });
  });
});

// Test file naming
// feature_service_test.dart
// feature_repository_test.dart
// feature_bloc_test.dart
// feature_widget_test.dart
```

### 3. BLoC Testing

#### BLoC Test Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:craft_marketplace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:craft_marketplace/features/auth/domain/repositories/auth_repository.dart';
import 'package:craft_marketplace/features/auth/domain/entities/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc', () {
    late AuthRepository mockAuthRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    const testUser = User(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    test('initial state should be AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(mockAuthRepository.signIn(any(), any()))
            .thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'test@example.com', password: 'password'),
      ),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(user: testUser),
      ],
      verify: (_) {
        verify(mockAuthRepository.signIn('test@example.com', 'password'))
            .called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(mockAuthRepository.signIn(any(), any()))
            .thenThrow(Exception('Invalid credentials'));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'test@example.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'does not emit new states when duplicate login events are added',
      build: () {
        when(mockAuthRepository.signIn(any(), any()))
            .thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) async {
        bloc.add(const LoginRequested(email: 'test@example.com', password: 'password'));
        bloc.add(const LoginRequested(email: 'test@example.com', password: 'password'));
        await Future.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(user: testUser),
      ],
    );
  });
}
```

### 4. Repository Testing

#### Repository Test Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

import 'package:craft_marketplace/features/video/data/repositories/video_repository_impl.dart';
import 'package:craft_marketplace/features/video/data/datasources/video_remote_data_source.dart';
import 'package:craft_marketplace/features/video/data/datasources/video_local_data_source.dart';
import 'package:craft_marketplace/features/video/domain/entities/video.dart';

class MockRemoteDataSource extends Mock implements VideoRemoteDataSource {}
class MockLocalDataSource extends Mock implements VideoLocalDataSource {}
class MockDio extends Mock implements Dio {}

void main() {
  group('VideoRepositoryImpl', () {
    late VideoRepositoryImpl repository;
    late MockRemoteDataSource mockRemoteDataSource;
    late MockLocalDataSource mockLocalDataSource;
    late MockDio mockDio;

    setUp(() {
      mockRemoteDataSource = MockRemoteDataSource();
      mockLocalDataSource = MockLocalDataSource();
      mockDio = MockDio();
      repository = VideoRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
        dio: mockDio,
      );
    });

    const testVideo = Video(
      id: 'test-video-id',
      title: 'Test Video',
      url: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      duration: Duration(seconds: 60),
    );

    group('getVideo', () {
      test('should return video from cache when available', () async {
        // Arrange
        when(mockLocalDataSource.getVideo(any()))
            .thenAnswer((_) async => testVideo);

        // Act
        final result = await repository.getVideo('test-video-id');

        // Assert
        expect(result, equals(testVideo));
        verify(mockLocalDataSource.getVideo('test-video-id')).called(1);
        verifyNever(mockRemoteDataSource.getVideo(any()));
      });

      test('should fetch video from remote source when not in cache', () async {
        // Arrange
        when(mockLocalDataSource.getVideo(any()))
            .thenThrow(Exception('Not found'));
        when(mockRemoteDataSource.getVideo(any()))
            .thenAnswer((_) async => testVideo);

        // Act
        final result = await repository.getVideo('test-video-id');

        // Assert
        expect(result, equals(testVideo));
        verify(mockLocalDataSource.getVideo('test-video-id')).called(1);
        verify(mockRemoteDataSource.getVideo('test-video-id')).called(1);
        verify(mockLocalDataSource.cacheVideo(testVideo)).called(1);
      });

      test('should throw NetworkException when remote source fails', () async {
        // Arrange
        when(mockLocalDataSource.getVideo(any()))
            .thenThrow(Exception('Not found'));
        when(mockRemoteDataSource.getVideo(any()))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/videos/test-video-id'),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act & Assert
        expect(
          () => repository.getVideo('test-video-id'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('searchVideos', () {
      test('should return list of videos for valid query', () async {
        // Arrange
        final testVideos = [testVideo, testVideo];
        when(mockRemoteDataSource.searchVideos(any(), any()))
            .thenAnswer((_) async => testVideos);

        // Act
        final result = await repository.searchVideos('test query');

        // Assert
        expect(result, equals(testVideos));
        verify(mockRemoteDataSource.searchVideos('test query', null))
            .called(1);
      });

      test('should pass pagination parameters correctly', () async {
        // Arrange
        when(mockRemoteDataSource.searchVideos(any(), any()))
            .thenAnswer((_) async => [testVideo]);

        // Act
        await repository.searchVideos(
          'test query',
          pagination: const Pagination(page: 2, limit: 20),
        );

        // Assert
        verify(mockRemoteDataSource.searchVideos(
          'test query',
          const Pagination(page: 2, limit: 20),
        )).called(1);
      });
    });
  });
}
```

### 5. Use Case Testing

#### Use Case Test Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:craft_marketplace/features/auction/domain/usecases/place_bid_usecase.dart';
import 'package:craft_marketplace/features/auction/domain/repositories/auction_repository.dart';
import 'package:craft_marketplace/features/auction/domain/entities/bid.dart';
import 'package:craft_marketplace/core/entities/money.dart';

class MockAuctionRepository extends Mock implements AuctionRepository {}

void main() {
  group('PlaceBidUseCase', () {
    late PlaceBidUseCase useCase;
    late MockAuctionRepository mockRepository;

    setUp(() {
      mockRepository = MockAuctionRepository();
      useCase = PlaceBidUseCase(mockRepository);
    });

    const testBid = Bid(
      id: 'test-bid-id',
      auctionId: 'test-auction-id',
      userId: 'test-user-id',
      amount: Money.fromDouble(100.0),
      timestamp: '2024-01-15T10:30:00Z',
    );

    test('should place bid successfully when valid', () async {
      // Arrange
      when(mockRepository.placeBid(any()))
          .thenAnswer((_) async => testBid);

      // Act
      final result = await useCase(const PlaceBidParams(
        auctionId: 'test-auction-id',
        userId: 'test-user-id',
        amount: Money.fromDouble(100.0),
      ));

      // Assert
      expect(result, equals(testBid));
      verify(mockRepository.placeBid(const PlaceBidParams(
        auctionId: 'test-auction-id',
        userId: 'test-user-id',
        amount: Money.fromDouble(100.0),
      ))).called(1);
    });

    test('should throw ValidationException when amount is too low', () async {
      // Arrange
      when(mockRepository.getMinimumBid(any()))
          .thenAnswer((_) async => const Money.fromDouble(150.0));

      // Act & Assert
      expect(
        () => useCase(const PlaceBidParams(
          auctionId: 'test-auction-id',
          userId: 'test-user-id',
          amount: Money.fromDouble(100.0),
        )),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should throw AuctionNotActiveException when auction has ended', () async {
      // Arrange
      when(mockRepository.placeBid(any()))
          .thenThrow(AuctionNotActiveException());

      // Act & Assert
      expect(
        () => useCase(const PlaceBidParams(
          auctionId: 'test-auction-id',
          userId: 'test-user-id',
          amount: Money.fromDouble(100.0),
        )),
        throwsA(isA<AuctionNotActiveException>()),
      );
    });
  });
}
```

## Widget Testing Strategy

### 1. Widget Testing Setup

#### Widget Test Utilities
Create `test/widget/widget_test_utils.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

/// Widget testing utilities and helpers.
class WidgetTestUtils {
  /// Wrap widget with MaterialApp for testing.
  static Widget createTestWidget({
    required Widget child,
    ThemeData? theme,
    Locale? locale,
    List<NavigatorObserver>? navigatorObservers,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      locale: locale ?? const Locale('en', 'US'),
      localizationsDelegates: const [
        // Add your localization delegates here
      ],
      home: Scaffold(body: child),
      navigatorObservers: navigatorObservers ?? [],
    );
  }

  /// Find widget by semantic label.
  static Finder findByLabel(String label) {
    return find.bySemanticsLabel(label);
  }

  /// Find widget by accessibility hint.
  static Finder findByHint(String hint) {
    return find.bySemanticsLabel(hint);
  }

  /// Wait for widget to appear.
  static Future<void> waitForWidget(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle(timeout);
    expect(finder, findsOneWidget);
  }

  /// Enter text into text field.
  static Future<void> enterText(
    Finder finder,
    String text, {
    bool clearFirst = true,
  }) async {
    if (clearFirst) {
      await tester.tap(finder);
      await tester.pump();
      await tester.enterText(finder, '');
    }
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Scroll widget into view.
  static Future<void> scrollIntoView(
    Finder finder, {
    Finder scrollable = find.byType(Scrollable),
    double delta = 100.0,
  }) async {
    try {
      await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
    } catch (e) {
      // If scrolling fails, try to find the widget directly
      expect(finder, findsOneWidget);
    }
  }
}
```

### 2. Widget Testing Examples

#### Simple Widget Test
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:craft_marketplace/shared/widgets/custom_button.dart';
import 'package:craft_marketplace/core/theme/app_theme.dart';

void main() {
  group('CustomButton', () {
    testWidgets('renders with correct text', (WidgetTester tester) async {
      // Arrange
      const buttonText = 'Click me';

      // Act
      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: const CustomButton(
            text: buttonText,
            onPressed: null,
          ),
        ),
      );

      // Assert
      expect(find.text(buttonText), findsOneWidget);
      expect(find.byType(CustomButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      // Arrange
      bool wasPressed = false;

      // Act
      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: CustomButton(
            text: 'Click me',
            onPressed: () => wasPressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(wasPressed, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: const CustomButton(
            text: 'Disabled Button',
            onPressed: null,
          ),
        ),
      );

      // Act
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

      // Assert
      expect(button.onPressed, isNull);
      expect(button.style?.backgroundColor?.resolve({}),
             equals(Colors.grey));
    });

    testWidgets('shows loading indicator when isLoading is true',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: const CustomButton(
            text: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing); // Text hidden during loading
    });

    testWidgets('applies custom theme colors correctly',
        (WidgetTester tester) async {
      // Arrange
      const customTheme = ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          theme: customTheme,
          child: const CustomButton(
            text: 'Themed Button',
            onPressed: () {},
          ),
        ),
      );

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor?.resolve({}), equals(Colors.purple));
    });
  });
}
```

#### Complex Widget Test
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:craft_marketplace/features/video/presentation/widgets/video_player_widget.dart';
import 'package:craft_marketplace/features/video/presentation/bloc/video_bloc.dart';

class MockVideoBloc extends Mock implements VideoBloc {}

void main() {
  group('VideoPlayerWidget', () {
    late VideoBloc mockVideoBloc;

    setUp(() {
      mockVideoBloc = MockVideoBloc();
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      // Arrange
      when(mockVideoBloc.state).thenReturn(const VideoLoading());

      // Act
      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: BlocProvider<VideoBloc>.value(
            value: mockVideoBloc,
            child: const VideoPlayerWidget(videoId: 'test-video-id'),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays video when loaded successfully',
        (WidgetTester tester) async {
      // Arrange
      const testVideo = Video(
        id: 'test-video-id',
        title: 'Test Video',
        url: 'https://example.com/video.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );

      when(mockVideoBloc.state).thenReturn(VideoLoaded(video: testVideo));

      // Act
      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: BlocProvider<VideoBloc>.value(
            value: mockVideoBloc,
            child: const VideoPlayerWidget(videoId: 'test-video-id'),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Video'), findsOneWidget);
      expect(find.byType(VideoPlayer), findsOneWidget);
    });

    testWidgets('shows error message when video fails to load',
        (WidgetTester tester) async {
      // Arrange
      when(mockVideoBloc.state).thenReturn(
        const VideoError(message: 'Failed to load video'),
      );

      // Act
      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: BlocProvider<VideoBloc>.value(
            value: mockVideoBloc,
            child: const VideoPlayerWidget(videoId: 'test-video-id'),
          ),
        ),
      );

      // Assert
      expect(find.text('Failed to load video'), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget); // Retry button
    });

    testWidgets('retries loading when retry button is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockVideoBloc.state).thenReturn(
        const VideoError(message: 'Failed to load video'),
      );

      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: BlocProvider<VideoBloc>.value(
            value: mockVideoBloc,
            child: const VideoPlayerWidget(videoId: 'test-video-id'),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      verify(mockVideoBloc.add(const VideoLoadRequested('test-video-id')))
          .called(1);
    });

    testWidgets('controls visibility changes on tap',
        (WidgetTester tester) async {
      // Arrange
      const testVideo = Video(
        id: 'test-video-id',
        title: 'Test Video',
        url: 'https://example.com/video.mp4',
      );

      when(mockVideoBloc.state).thenReturn(VideoLoaded(video: testVideo));

      await tester.pumpWidget(
        WidgetTestUtils.createTestWidget(
          child: BlocProvider<VideoBloc>.value(
            value: mockVideoBloc,
            child: const VideoPlayerWidget(videoId: 'test-video-id'),
          ),
        ),
      );

      // Initially controls should be visible
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      // Act - tap to hide controls
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert - controls should be hidden
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.volume_up), findsNothing);

      // Act - tap again to show controls
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert - controls should be visible again
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });
  });
}
```

## Integration Testing Strategy

### 1. Integration Testing Setup

#### Integration Test Configuration
Create `integration_test/app_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:craft_marketplace/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Craft Video Marketplace E2E Tests', () {
    testWidgets('complete user registration flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to registration
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Fill registration form
      await tester.enterText(find.byKey(const Key('email_field')),
                             'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')),
                             'SecurePassword123!');
      await tester.enterText(find.byKey(const Key('display_name_field')),
                             'Test User');

      // Accept terms
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pumpAndSettle();

      // Submit registration
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify registration success
      expect(find.text('Registration successful'), findsOneWidget);
      expect(find.byKey(const Key('verification_notice')), findsOneWidget);
    });

    testWidgets('complete login flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Fill login form
      await tester.enterText(find.byKey(const Key('email_field')),
                             'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')),
                             'password123');

      // Submit login
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify login success
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
      expect(find.text('Welcome, Test User'), findsOneWidget);
    });

    testWidgets('video viewing and interaction flow',
        (WidgetTester tester) async {
      // Start app and login
      await _performLogin(tester);

      // Navigate to video feed
      await tester.tap(find.byIcon(Icons.video_library));
      await tester.pumpAndSettle();

      // Select first video
      await tester.tap(find.byType(VideoCard).first);
      await tester.pumpAndSettle();

      // Verify video player is loaded
      expect(find.byType(VideoPlayerWidget), findsOneWidget);

      // Test video controls
      await tester.tap(find.byType(VideoPlayerWidget));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Test like functionality
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('auction bidding flow', (WidgetTester tester) async {
      // Start app and login
      await _performLogin(tester);

      // Navigate to auction
      await tester.tap(find.text('Auctions'));
      await tester.pumpAndSettle();

      // Select active auction
      await tester.tap(find.byType(AuctionCard).first);
      await tester.pumpAndSettle();

      // Place bid
      await tester.enterText(find.byKey(const Key('bid_amount_field')), '150');
      await tester.tap(find.byKey(const Key('place_bid_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify bid placed
      expect(find.text('Bid placed successfully!'), findsOneWidget);
      expect(find.text('Current bid: \$150'), findsOneWidget);
    });
  });
}

Future<void> _performLogin(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(const Key('password_field')), 'password123');

  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}
```

### 2. API Integration Testing

#### API Test Setup
Create `integration_test/api_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:craft_marketplace/core/network/api_client.dart';
import 'package:craft_marketplace/core/network/exceptions.dart';

void main() {
  group('API Integration Tests', () {
    late Dio dio;
    late ApiClient apiClient;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'https://api-staging.craft.marketplace/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      apiClient = ApiClient(dio);
    });

    group('Authentication Endpoints', () {
      test('should register user successfully', () async {
        // Arrange
        final registrationData = {
          'email': 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
          'password': 'SecurePassword123!',
          'displayName': 'Test User',
          'agreeToTerms': true,
        };

        // Act
        final response = await apiClient.post('/auth/register', data: registrationData);

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['success'], isTrue);
        expect(response.data['data']['userId'], isNotEmpty);
        expect(response.data['data']['email'], equals(registrationData['email']));
      });

      test('should login user successfully', () async {
        // First register a user
        final registrationData = {
          'email': 'login-test${DateTime.now().millisecondsSinceEpoch}@example.com',
          'password': 'SecurePassword123!',
          'displayName': 'Login Test',
          'agreeToTerms': true,
        };

        await apiClient.post('/auth/register', data: registrationData);

        // Now try to login
        final loginData = {
          'email': registrationData['email'],
          'password': registrationData['password'],
        };

        // Act
        final response = await apiClient.post('/auth/login', data: loginData);

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['success'], isTrue);
        expect(response.data['data']['token'], isNotEmpty);
        expect(response.data['data']['user']['email'], equals(loginData['email']));
      });

      test('should reject invalid credentials', () async {
        // Arrange
        final invalidLoginData = {
          'email': 'nonexistent@example.com',
          'password': 'wrongpassword',
        };

        // Act & Assert
        expect(
          () => apiClient.post('/auth/login', data: invalidLoginData),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('Video Endpoints', () {
      String? authToken;

      setUpAll(() async {
        // Login to get auth token
        final loginData = {
          'email': 'video-test@example.com',
          'password': 'SecurePassword123!',
        };

        final response = await apiClient.post('/auth/login', data: loginData);
        authToken = response.data['data']['token'];
      });

      test('should upload video successfully', () async {
        // Arrange
        final videoData = {
          'title': 'Test Video Upload',
          'description': 'This is a test video upload',
          'tags': ['test', 'upload'],
          'categoryId': 'electronics',
        };

        // Act
        final response = await apiClient.post(
          '/videos',
          data: videoData,
          options: Options(
            headers: {'Authorization': 'Bearer $authToken'},
          ),
        );

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['success'], isTrue);
        expect(response.data['data']['id'], isNotEmpty);
        expect(response.data['data']['title'], equals(videoData['title']));
      });

      test('should retrieve video list', () async {
        // Act
        final response = await apiClient.get('/videos');

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['success'], isTrue);
        expect(response.data['data']['videos'], isA<List>());
        expect(response.data['data']['pagination'], isA<Map>());
      });

      test('should search videos', () async {
        // Act
        final response = await apiClient.get('/videos/search?q=test');

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['success'], isTrue);
        expect(response.data['data']['videos'], isA<List>());
      });
    });

    group('Auction Endpoints', () {
      String? authToken;
      String? auctionId;

      setUpAll(() async {
        // Login to get auth token
        final loginData = {
          'email': 'auction-test@example.com',
          'password': 'SecurePassword123!',
        };

        final response = await apiClient.post('/auth/login', data: loginData);
        authToken = response.data['data']['token'];
      });

      test('should create auction successfully', () async {
        // Arrange
        final auctionData = {
          'videoId': 'test-video-id',
          'startingPrice': 10000, // $100.00 in cents
          'reservePrice': 15000,  // $150.00 in cents
          'duration': 3600,       // 1 hour in seconds
          'startTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        };

        // Act
        final response = await apiClient.post(
          '/auctions',
          data: auctionData,
          options: Options(
            headers: {'Authorization': 'Bearer $authToken'},
          ),
        );

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['success'], isTrue);
        auctionId = response.data['data']['id'];
        expect(auctionId, isNotEmpty);
      });

      test('should place bid successfully', () async {
        if (auctionId == null) return;

        // Arrange
        final bidData = {
          'amount': 11000, // $110.00 in cents
        };

        // Act
        final response = await apiClient.post(
          '/auctions/$auctionId/bids',
          data: bidData,
          options: Options(
            headers: {'Authorization': 'Bearer $authToken'},
          ),
        );

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.data['success'], isTrue);
        expect(response.data['data']['id'], isNotEmpty);
      });

      test('should retrieve auction details', () async {
        if (auctionId == null) return;

        // Act
        final response = await apiClient.get('/auctions/$auctionId');

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.data['success'], isTrue);
        expect(response.data['data']['id'], equals(auctionId));
        expect(response.data['data']['bids'], isA<List>());
      });
    });
  });
}
```

## Performance Testing

### 1. Performance Testing Setup

#### Performance Test Configuration
Create `test/performance/performance_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:craft_marketplace/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Tests', () {
    testWidgets('app startup performance', (WidgetTester tester) async {
      // Record startup time
      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Assert startup time is acceptable (< 3 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      // Record performance metrics
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      await binding.reportData();
    });

    testWidgets('scrolling performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to video feed
      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();

      // Record scrolling performance
      final scrollFinder = find.byType(ListView);

      // Simulate scrolling
      await tester.fling(scrollFinder, const Offset(0, -500), 10000);
      await tester.pumpAndSettle();

      // Continue scrolling
      for (int i = 0; i < 10; i++) {
        await tester.fling(scrollFinder, const Offset(0, -200), 5000);
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      // Performance should remain smooth
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      await binding.reportData();
    });

    testWidgets('video player performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to video
      await tester.tap(find.byType(VideoCard).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Measure video load time
      final loadStopwatch = Stopwatch()..start();

      // Wait for video to fully load
      await tester.pumpUntil(find.byType(VideoPlayerWidget));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      loadStopwatch.stop();

      // Assert video loads within acceptable time (< 5 seconds)
      expect(loadStopwatch.elapsedMilliseconds, lessThan(5000));

      // Test video controls responsiveness
      final controlStopwatch = Stopwatch()..start();

      await tester.tap(find.byType(VideoPlayerWidget));
      await tester.pump();

      controlStopwatch.stop();

      // Controls should respond quickly (< 100ms)
      expect(controlStopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
```

### 2. Memory Testing

#### Memory Leak Detection
Create `test/performance/memory_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:craft_marketplace/features/video/presentation/widgets/video_player_widget.dart';

void main() {
  group('Memory Tests', () {
    testWidgets('video player widget disposes properly',
        (WidgetTester tester) async {
      // Arrange
      final memoryBefore = _getCurrentMemoryUsage();

      // Create and display video player
      await tester.pumpWidget(
        MaterialApp(
          home: VideoPlayerWidget(
            videoUrl: 'https://example.com/test.mp4',
            thumbnailUrl: 'https://example.com/thumb.jpg',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Let video player initialize
      await tester.pump(const Duration(seconds: 3));

      // Remove widget from tree
      await tester.pumpWidget(Container());
      await tester.pump();

      // Force garbage collection
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/memorypressure',
        StringCodec().encodeMessage('normal'),
        (data) {},
      );
      await tester.pump();

      // Check memory after disposal
      final memoryAfter = _getCurrentMemoryUsage();
      final memoryIncrease = memoryAfter - memoryBefore;

      // Memory increase should be minimal (< 10MB)
      expect(memoryIncrease, lessThan(10 * 1024 * 1024));
    });

    testWidgets('large list scrolling memory usage',
        (WidgetTester tester) async {
      // Arrange
      final memoryBefore = _getCurrentMemoryUsage();

      // Create list with 1000 items
      await tester.pumpWidget(
        MaterialApp(
          home: ListView.builder(
            itemCount: 1000,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Item $index'),
                subtitle: Text('Subtitle for item $index'),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll through entire list
      final scrollable = find.byType(Scrollable);
      for (int i = 0; i < 50; i++) {
        await tester.fling(scrollable, const Offset(0, -1000), 5000);
        await tester.pumpAndSettle();
      }

      final memoryAfter = _getCurrentMemoryUsage();
      final memoryIncrease = memoryAfter - memoryBefore;

      // Memory usage should be reasonable for large list (< 50MB)
      expect(memoryIncrease, lessThan(50 * 1024 * 1024));
    });
  });
}

int _getCurrentMemoryUsage() {
  // This would need to be implemented based on platform-specific APIs
  // For now, return a mock value
  return 0;
}
```

## Accessibility Testing

### 1. Accessibility Test Setup

#### Accessibility Configuration
Create `test/accessibility/accessibility_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:craft_marketplace/main.dart' as app;

void main() {
  group('Accessibility Tests', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    testWidgets('app has proper semantic labels', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Check that important elements have semantic labels
      expect(
        find.bySemanticsLabel('Create Account'),
        findsOneWidget,
        reason: 'Registration button should have semantic label',
      );

      expect(
        find.bySemanticsLabel('Sign In'),
        findsOneWidget,
        reason: 'Login button should have semantic label',
      );

      expect(
        find.bySemanticsLabel(RegExp(r'Email', caseSensitive: false)),
        findsOneWidget,
        reason: 'Email field should have semantic label',
      );

      expect(
        find.bySemanticsLabel(RegExp(r'Password', caseSensitive: false)),
        findsOneWidget,
        reason: 'Password field should have semantic label',
      );
    });

    testWidgets('form fields have proper accessibility hints',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Check email field
      final emailField = find.byKey(const Key('email_field'));
      expect(emailField, findsOneWidget);

      final emailSemantics = tester.getSemantics(emailField);
      expect(
        emailSemantics.hints,
        contains(RegExp(r'enter.*email', caseSensitive: false)),
        reason: 'Email field should have hint about entering email',
      );

      // Check password field
      final passwordField = find.byKey(const Key('password_field'));
      expect(passwordField, findsOneWidget);

      final passwordSemantics = tester.getSemantics(passwordField);
      expect(
        passwordSemantics.hints,
        contains(RegExp(r'enter.*password', caseSensitive: false)),
        reason: 'Password field should have hint about entering password',
      );
    });

    testWidgets('important actions have increased contrast',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test high contrast mode
      final highContrastData = ThemeData.light().copyWith(
        colorScheme: ColorScheme.light().copyWith(
          primary: Colors.black,
          onPrimary: Colors.white,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: highContrastData,
          home: const Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: Text('Important Action'),
            ),
          ),
        ),
      );

      // Verify contrast ratio (this would need a custom implementation)
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor?.resolve({}), isNotNull);
    });

    testWidgets('focus order is logical', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Test tab order
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // First element should be email field
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        contains('email'),
        reason: 'Email field should be first in tab order',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Second element should be password field
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        contains('password'),
        reason: 'Password field should be second in tab order',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Third element should be display name field
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        contains('display name'),
        reason: 'Display name field should be third in tab order',
      );
    });

    testWidgets('screen reader reads content correctly',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enable accessibility
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      binding.enableSemantics();

      // Navigate to a video
      await tester.tap(find.byType(VideoCard).first);
      await tester.pumpAndSettle();

      // Check that important information is announced
      expect(
        find.bySemanticsLabel(RegExp(r'video.*title', caseSensitive: false)),
        findsOneWidget,
        reason: 'Video title should be announced',
      );

      expect(
        find.bySemanticsLabel(RegExp(r'play.*button', caseSensitive: false)),
        findsOneWidget,
        reason: 'Play button should be announced',
      );

      expect(
        find.bySemanticsLabel(RegExp(r'volume.*control', caseSensitive: false)),
        findsOneWidget,
        reason: 'Volume control should be announced',
      );
    });
  });
}
```

## Continuous Integration Testing

### 1. GitHub Actions Configuration

#### CI/CD Pipeline
Create `.github/workflows/test.yml`:
```yaml
name: Flutter Tests

on:
  push:
    branches: [ develop, main ]
  pull_request:
    branches: [ develop ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: |
          flutter packages pub run build_runner build --delete-conflicting-outputs

      - name: Analyze code
        run: flutter analyze --fatal-infos --fatal-warnings

      - name: Run unit tests
        run: flutter test --coverage --reporter=expanded

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
          flags: unit-tests

      - name: Run widget tests
        run: flutter test test/widget --coverage --reporter=expanded

      - name: Run integration tests
        run: |
          flutter pub global activate integration_test
          flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart

  performance:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'

      - name: Install dependencies
        run: flutter pub get

      - name: Run performance tests
        run: flutter test test/performance

  accessibility:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.x'

      - name: Install dependencies
        run: flutter pub get

      - name: Run accessibility tests
        run: flutter test test/accessibility

  security:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Run security scan
        run: |
          flutter pub deps --style=compact
          # Add additional security scanning tools here
```

## Testing Best Practices

### 1. Test Organization

#### Test Structure Guidelines
```dart
// Test structure: AAA (Arrange, Act, Assert)
test('should do X when Y', () async {
  // Arrange - Set up test conditions
  final mockRepository = MockRepository();
  when(mockRepository.getData()).thenReturn(mockData);

  // Act - Execute the code being tested
  final result = await serviceUnderTest.getData();

  // Assert - Verify the outcome
  expect(result, equals(expectedResult));
});
```

#### Test Data Management
```dart
// Create test data factories
class TestDataFactory {
  static User createTestUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
    );
  }

  static Video createTestVideo({
    String id = 'test-video-id',
    String title = 'Test Video',
  }) {
    return Video(
      id: id,
      title: title,
      url: 'https://example.com/video.mp4',
    );
  }
}
```

### 2. Mocking Strategies

#### Effective Mocking
```dart
// Use mocks for external dependencies
class MockApiService extends Mock implements ApiService {}

// Configure mocks with specific behavior
void setUpMockApiService(MockApiService mockApi) {
  when(mockApi.getVideos())
      .thenAnswer((_) async => [testVideo1, testVideo2]);

  when(mockApi.uploadVideo(any()))
      .thenThrow(ApiException('Upload failed'));

  when(mockApi.deleteVideo(any()))
      .thenAnswer((_) async => true);
}
```

### 3. Test Utilities

#### Common Test Helpers
```dart
// Reusable test utilities
class TestHelpers {
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      await tester.pumpAndSettle(timeout);
    } catch (e) {
      // Handle timeout gracefully
      throw TestTimeoutException('Test timed out after $timeout');
    }
  }

  static Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await tester.pump();
      if (tester.any(finder)) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    throw TestTimeoutException('Widget not found within timeout');
  }
}
```

## Validation Checklist

### Testing Coverage
- [ ] Unit test coverage ≥ 80% for business logic
- [ ] Critical flows have 100% test coverage
- [ ] Integration tests cover all major user workflows
- [ ] E2E tests cover critical user journeys
- [ ] Performance tests meet benchmark requirements
- [ ] Accessibility tests satisfy WCAG 2.1 AA standards

### Test Quality
- [ ] Tests are readable and maintainable
- [ ] Test data is well-organized and reusable
- [ ] Mocks are used appropriately
- [ ] Tests are independent and isolated
- [ ] Test descriptions are clear and descriptive

### CI/CD Integration
- [ ] All tests run on pull requests
- [ ] Test failures block merges
- [ ] Coverage reports are generated
- [ ] Performance benchmarks are tracked
- [ ] Security scans are automated

### Documentation
- [ ] Testing strategy is documented
- [ ] Test conventions are established
- [ ] Team training materials are available
- [ ] Test results are easily accessible
- [ ] Best practices are regularly reviewed

This comprehensive testing strategy ensures high-quality code, reliable features, and excellent user experience across all supported platforms of the Craft Video Marketplace application.