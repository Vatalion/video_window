# Unit Testing Guide

**Effective Date:** 2025-10-09
**Target Framework:** Flutter 3.19.6
**Coverage Target:** 80%+ for business logic, 95%+ for critical paths

## Overview

Unit testing focuses on testing individual components in isolation. This guide covers best practices for testing BLoCs, use cases, repositories, models, and widgets using Flutter's testing framework and supporting packages.

## Testing Philosophy

### What to Test

**Business Logic**
- BLoC state transitions
- Use case behavior
- Repository implementations
- Data model serialization/deserialization
- Utility functions

**UI Components**
- Widget rendering
- User interactions
- State changes
- Error conditions

### What NOT to Test

**Third-Party Libraries**
- Framework code (Flutter, Serverpod)
- External package implementations
- System APIs (unless custom wrapper)

**Implementation Details**
- Private methods
- Internal state that doesn't affect public API
- Specific implementation algorithms

## Testing Tools Setup

### Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # Testing frameworks
  mocktail: ^1.0.3           # Modern mocking library
  bloc_test: ^9.1.7         # BLoC testing utilities
  golden_toolkit: ^0.15.0   # Widget screenshot testing

  # Testing utilities
  fake_async: ^1.3.1        # Time control in tests
  clock: ^1.1.1             # Time mocking
  network_image_mock: ^2.1.1 # Network image mocking

  # Code quality
  very_good_analysis: ^5.1.0
```

### Test Configuration

```dart
// test/test_helpers/test_config.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void setUpAllTests() {
  // Register fallback values for mocks
  registerFallbackValue(const Duration(seconds: 1));
  registerFallbackValue(MyModel.defaultInstance());

  // Configure test behavior
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up global mocks if needed
  setUpMockServices();
}

void setUpMockServices() {
  // Initialize any mock services needed across tests
}
```

## BLoC Testing

### Basic BLoC Test Structure

```dart
// test/unit/features/feed/bloc/feed_bloc_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/feed/presentation/bloc/feed_bloc.dart';
import 'package:video_window/features/feed/domain/usecases/load_feed_usecase.dart';
import 'package:video_window/features/feed/domain/entities/story_entity.dart';

class MockLoadFeedUseCase extends Mock implements LoadFeedUseCase {}

void main() {
  group('FeedBloc', () {
    late LoadFeedUseCase mockLoadFeedUseCase;
    late FeedBloc feedBloc;

    setUp(() {
      mockLoadFeedUseCase = MockLoadFeedUseCase();
      feedBloc = FeedBloc(loadFeed: mockLoadFeedUseCase);
    });

    tearDown(() {
      feedBloc.close();
    });

    // Test data
    const testStory = StoryEntity(
      id: '1',
      makerId: '2',
      title: 'Handmade Ceramic Vase',
      description: 'Beautiful handcrafted ceramic vase',
      videoUrl: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      category: 'pottery',
      tags: ['ceramic', 'handmade'],
      minimumOffer: 50.0,
      buyItNowPrice: 150.0,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    test('initial state is FeedInitial', () {
      expect(feedBloc.state, equals(FeedInitial()));
    });

    blocTest<FeedBloc, FeedState>(
      'emits [FeedLoading, FeedLoaded] when feed loads successfully',
      setUp: () {
        when(() => mockLoadFeedUseCase(any()))
            .thenAnswer((_) async => [testStory]);
      },
      build: () => feedBloc,
      act: (bloc) => bloc.add(const FeedRequested()),
      expect: () => [
        FeedLoading(),
        const FeedLoaded(stories: [testStory]),
      ],
      verify: (_) {
        verify(() => mockLoadFeedUseCase(any())).called(1);
      },
    );

    blocTest<FeedBloc, FeedState>(
      'emits [FeedLoading, FeedError] when feed load fails',
      setUp: () {
        when(() => mockLoadFeedUseCase(any()))
            .thenThrow(Exception('Network error'));
      },
      build: () => feedBloc,
      act: (bloc) => bloc.add(const FeedRequested()),
      expect: () => [
        FeedLoading(),
        const FeedError(message: 'Failed to load feed'),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'emits [FeedLoaded, FeedLoading, FeedLoaded] when feed refreshes',
      setUp: () {
        when(() => mockLoadFeedUseCase(any()))
            .thenAnswer((_) async => [testStory]);
      },
      build: () => feedBloc,
      seed: () => const FeedLoaded(stories: []),
      act: (bloc) => bloc.add(const FeedRefreshed()),
      expect: () => [
        const FeedLoaded(stories: []),
        FeedLoading(),
        const FeedLoaded(stories: [testStory]),
      ],
    );
  });
}
```

### Complex BLoC Testing with Time

```dart
// test/unit/features/auction/bloc/auction_bloc_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_async/fake_async.dart';
import 'package:video_window/features/auction/presentation/bloc/auction_bloc.dart';
import 'package:video_window/features/auction/domain/entities/auction_entity.dart';

void main() {
  group('AuctionBloc - Timer Behavior', () {
    late AuctionBloc auctionBloc;

    setUp(() {
      auctionBloc = AuctionBloc();
    });

    tearDown(() {
      auctionBloc.close();
    });

    blocTest<AuctionBloc, AuctionState>(
      'emits timer updates every second',
      build: () => auctionBloc,
      seed: () => AuctionState(
        auction: testAuction,
        timeRemaining: const Duration(minutes: 5),
      ),
      act: (bloc) => bloc.startTimer(),
      expect: () => [
        // Initial state
        AuctionState(
          auction: testAuction,
          timeRemaining: const Duration(minutes: 5),
        ),
        // After 1 second
        AuctionState(
          auction: testAuction,
          timeRemaining: const Duration(minutes: 4, seconds: 59),
        ),
        // After 2 seconds
        AuctionState(
          auction: testAuction,
          timeRemaining: const Duration(minutes: 4, seconds: 58),
        ),
      ],
      wait: const Duration(seconds: 2),
    );

    test('handles auction end correctly when timer reaches zero', () {
      fakeAsync((async) {
        auctionBloc.add(AuctionStarted(auction: testAuction));

        // Fast-forward 5 minutes
        async.elapse(const Duration(minutes: 5));

        expect(auctionBloc.state, isA<AuctionEnded>());
      });
    });
  });
}
```

## Use Case Testing

### Basic Use Case Test

```dart
// test/unit/features/auth/domain/usecases/sign_in_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/domain/entities/user_entity.dart';
import 'package:video_window/features/auth/domain/repositories/auth_repository.dart';
import 'package:video_window/features/auth/domain/usecases/sign_in_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SignInWithEmailUseCase', () {
    late SignInWithEmailUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SignInWithEmailUseCase(repository: mockRepository);
    });

    // Test data
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
      )).thenThrow(const AuthException('Invalid credentials'));

      // Act
      final call = useCase.call;

      // Assert
      expect(
        () => call(email: 'test@example.com', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });

    test('should validate email format', () async {
      // Act & Assert
      expect(
        () => useCase.call(email: 'invalid-email', password: 'password123'),
        throwsA(isA<ValidationException>()),
      );

      verifyNever(() => mockRepository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ));
    });

    test('should validate password length', () async {
      // Act & Assert
      expect(
        () => useCase.call(email: 'test@example.com', password: '123'),
        throwsA(isA<ValidationException>()),
      );

      verifyNever(() => mockRepository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ));
    });
  });
}
```

### Use Case with Parameters

```dart
// test/unit/features/feed/domain/usecases/load_feed_usecase_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/feed/domain/entities/story_entity.dart';
import 'package:video_window/features/feed/domain/repositories/feed_repository.dart';
import 'package:video_window/features/feed/domain/usecases/load_feed_usecase.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  group('LoadFeedUseCase', () {
    late LoadFeedUseCase useCase;
    late MockFeedRepository mockRepository;

    setUp(() {
      mockRepository = MockFeedRepository();
      useCase = LoadFeedUseCase(repository: mockRepository);
    });

    test('should return stories when repository succeeds', () async {
      // Arrange
      const testStories = [
        StoryEntity(
          id: '1',
          makerId: '2',
          title: 'Story 1',
          description: 'Description 1',
          videoUrl: 'https://example.com/video1.mp4',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          category: 'pottery',
          tags: ['test'],
          minimumOffer: 50.0,
          buyItNowPrice: 150.0,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
        StoryEntity(
          id: '2',
          makerId: '3',
          title: 'Story 2',
          description: 'Description 2',
          videoUrl: 'https://example.com/video2.mp4',
          thumbnailUrl: 'https://example.com/thumb2.jpg',
          category: 'jewelry',
          tags: ['test'],
          minimumOffer: 75.0,
          buyItNowPrice: 200.0,
          createdAt: DateTime(2025, 1, 2),
          updatedAt: DateTime(2025, 1, 2),
        ),
      ];

      when(() => mockRepository.getStories(
        category: any(named: 'category'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      )).thenAnswer((_) async => testStories);

      // Act
      final result = await useCase(
        category: 'pottery',
        limit: 10,
        offset: 0,
      );

      // Assert
      expect(result, equals(testStories));
      verify(() => mockRepository.getStories(
        category: 'pottery',
        limit: 10,
        offset: 0,
      )).called(1);
    });

    test('should apply default parameters when not provided', () async {
      // Arrange
      when(() => mockRepository.getStories(
        category: any(named: 'category'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      )).thenAnswer((_) async => []);

      // Act
      await useCase();

      // Assert
      verify(() => mockRepository.getStories(
        category: null,
        limit: 20,
        offset: 0,
      )).called(1);
    });
  });
}
```

## Repository Testing

### Repository Implementation Test

```dart
// test/unit/features/auth/data/repositories/auth_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:video_window/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:video_window/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:video_window/features/auth/data/models/user_model.dart';
import 'package:video_window/features/auth/domain/entities/user_entity.dart';

class MockRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  group('AuthRepositoryImpl', () {
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

    // Test data
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

    group('signInWithEmail', () {
      test('should cache user when sign in succeeds', () async {
        // Arrange
        when(() => mockRemoteDataSource.signInWithEmail(any()))
            .thenAnswer((_) async => testUserModel);
        when(() => mockLocalDataSource.cacheUser(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isA<UserEntity>());
        expect(result.email, equals(testUserModel.email));
        verify(() => mockLocalDataSource.cacheUser(testUserModel)).called(1);
      });

      test('should propagate exception when remote data source fails', () async {
        // Arrange
        when(() => mockRemoteDataSource.signInWithEmail(any()))
            .thenThrow(const NetworkException('Network error'));

        // Act
        final call = repository.signInWithEmail;

        // Assert
        expect(
          () => call(email: 'test@example.com', password: 'password123'),
          throwsA(isA<NetworkException>()),
        );
        verifyNever(() => mockLocalDataSource.cacheUser(any()));
      });

      test('should clear cache when sign in fails after caching', () async {
        // Arrange
        when(() => mockRemoteDataSource.signInWithEmail(any()))
            .thenThrow(const AuthException('Invalid credentials'));
        when(() => mockLocalDataSource.cacheUser(any()))
            .thenThrow(const CacheException('Cache write failed'));
        when(() => mockLocalDataSource.clearCache())
            .thenAnswer((_) async {});

        // Act
        final call = repository.signInWithEmail;

        // Assert
        expect(
          () => call(email: 'test@example.com', password: 'wrong'),
          throwsA(isA<AuthException>()),
        );
        verify(() => mockLocalDataSource.clearCache()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return cached user when available', () async {
        // Arrange
        when(() => mockLocalDataSource.getCachedUser())
            .thenAnswer((_) async => testUserModel);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, equals(testUserModel.toEntity()));
        verify(() => mockLocalDataSource.getCachedUser()).called(1);
        verifyNever(() => mockRemoteDataSource.signInWithEmail(any()));
      });

      test('should return null when no cached user exists', () async {
        // Arrange
        when(() => mockLocalDataSource.getCachedUser())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
        verify(() => mockLocalDataSource.getCachedUser()).called(1);
      });
    });
  });
}
```

## Model Testing

### JSON Serialization Tests

```dart
// test/unit/features/auth/data/models/user_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel Serialization', () {
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

    test('should handle missing optional fields', () {
      // Arrange
      const jsonWithoutOptionals = {
        'id': '1',
        'email': 'test@example.com',
        'isEmailVerified': true,
        'isMaker': false,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-01T00:00:00.000Z',
        'providers': ['email'],
      };

      // Act
      final result = UserModel.fromJson(jsonWithoutOptionals);

      // Assert
      expect(result.displayName, isNull);
      expect(result.photoUrl, isNull);
      expect(result.metadata, isNull);
    });

    test('should handle invalid date format gracefully', () {
      // Arrange
      final jsonWithInvalidDate = Map<String, dynamic>.from(testJson)
        ..['createdAt'] = 'invalid-date';

      // Act
      expect(
        () => UserModel.fromJson(jsonWithInvalidDate),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('UserModel Entity Conversion', () {
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

    test('should convert to entity correctly', () {
      // Act
      final entity = testUserModel.toEntity();

      // Assert
      expect(entity.id, equals(testUserModel.id));
      expect(entity.email, equals(testUserModel.email));
      expect(entity.displayName, equals(testUserModel.displayName));
      expect(entity.isEmailVerified, equals(testUserModel.isEmailVerified));
      expect(entity.isMaker, equals(testUserModel.isMaker));
      expect(entity.createdAt, equals(testUserModel.createdAt));
      expect(entity.updatedAt, equals(testUserModel.updatedAt));
      expect(entity.providers, equals(testUserModel.providers));
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

  group('UserModel Validation', () {
    test('should validate email format', () {
      // Arrange
      const invalidEmailJson = {
        'id': '1',
        'email': 'invalid-email',
        'isEmailVerified': true,
        'isMaker': false,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-01T00:00:00.000Z',
        'providers': ['email'],
      };

      // Act & Assert
      expect(
        () => UserModel.fromJson(invalidEmailJson),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should validate required fields', () {
      // Arrange
      const incompleteJson = {
        'id': '1',
        'email': 'test@example.com',
        // Missing isEmailVerified
        'isMaker': false,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-01T00:00:00.000Z',
        'providers': ['email'],
      };

      // Act & Assert
      expect(
        () => UserModel.fromJson(incompleteJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
```

## Widget Testing

### Simple Widget Test

```dart
// test/widget/common/loading_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/shared/widgets/loading_widget.dart';

void main() {
  group('LoadingWidget', () {
    testWidgets('displays loading indicator correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays custom message when provided', (tester) async {
      const customMessage = 'Loading your stories...';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: customMessage),
          ),
        ),
      );

      // Assert
      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('uses custom color when provided', (tester) async {
      const customColor = Colors.purple;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingWidget(color: customColor),
          ),
        ),
      );

      // Assert
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, equals(customColor));
    });
  });
}
```

### Interactive Widget Test

```dart
// test/widget/auth/email_form_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:video_window/features/auth/presentation/widgets/email_form.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  group('EmailForm', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: Scaffold(
            body: EmailForm(),
          ),
        ),
      );
    }

    testWidgets('displays form fields correctly', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('enables sign in button when form is valid', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid data
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.pump();

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('disables sign in button when form is invalid', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid email
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalid-email',
      );
      await tester.pump();

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('submits form when sign in button is pressed', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert
      verify(() => mockAuthBloc.add(const SignInEmailRequested(
        email: 'test@example.com',
        password: 'password123',
      ))).called(1);
    });

    testWidgets('shows error message for invalid email', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalid-email',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error message for short password', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
        find.byKey(const Key('password_field')),
        '123',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Assert
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.byKey(const Key('password_field'));
      final toggleButton = find.byIcon(Icons.visibility_outlined);

      // Initially password should be obscured
      expect(tester.widget<TextFormField>(passwordField).obscureText, isTrue);

      // Tap visibility toggle
      await tester.tap(toggleButton);
      await tester.pump();

      // Password should be visible
      expect(tester.widget<TextFormField>(passwordField).obscureText, isFalse);

      // Tap visibility toggle again
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Password should be obscured again
      expect(tester.widget<TextFormField>(passwordField).obscureText, isTrue);
    });
  });
}
```

### Widget Test with Mock Data

```dart
// test/widget/feed/story_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:video_window/features/feed/presentation/widgets/story_card.dart';
import 'package:video_window/features/feed/domain/entities/story_entity.dart';

void main() {
  group('StoryCard', () {
    const testStory = StoryEntity(
      id: '1',
      makerId: '2',
      title: 'Handmade Ceramic Vase',
      description: 'Beautiful handcrafted ceramic vase with unique glazing',
      videoUrl: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      category: 'pottery',
      tags: ['ceramic', 'handmade'],
      minimumOffer: 50.0,
      buyItNowPrice: 150.0,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    testWidgets('displays story information correctly', (tester) async {
      // Act
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryCard(
                story: testStory,
                onTap: () {},
              ),
            ),
          ),
        );
      });

      // Assert
      expect(find.text('Handmade Ceramic Vase'), findsOneWidget);
      expect(find.text('Beautiful handcrafted ceramic vase with unique glazing'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      // Arrange
      var wasTapped = false;

      // Act
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryCard(
                story: testStory,
                onTap: () => wasTapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(StoryCard));
        await tester.pump();
      });

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('shows like button when liked', (tester) async {
      // Act
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryCard(
                story: testStory,
                isLiked: true,
                likes: 42,
                onTap: () {},
              ),
            ),
          ),
        );
      });

      // Assert
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows outline like button when not liked', (tester) async {
      // Act
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryCard(
                story: testStory,
                isLiked: false,
                likes: 42,
                onTap: () {},
              ),
            ),
          ),
        );
      });

      // Assert
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });
  });
}
```

## Test Helpers and Utilities

### Mock Utilities

```dart
// test/test_helpers/mock_helpers.dart

import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/domain/entities/user_entity.dart';
import 'package:video_window/features/feed/domain/entities/story_entity.dart';

class MockHelpers {
  static void registerFallbackValues() {
    registerFallbackValue(const UserEntity(
      id: '1',
      email: 'test@example.com',
      isEmailVerified: true,
      isMaker: false,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      providers: ['email'],
    ));

    registerFallbackValue(const StoryEntity(
      id: '1',
      makerId: '2',
      title: 'Test Story',
      description: 'Test Description',
      videoUrl: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      category: 'test',
      tags: ['test'],
      minimumOffer: 50.0,
      buyItNowPrice: 150.0,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ));

    registerFallbackValue(const Duration(seconds: 1));
    registerFallbackValue(const Duration(minutes: 5));
  }

  static UserEntity createTestUser({
    String id = '1',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool isEmailVerified = true,
    bool isMaker = false,
    List<String> providers = const ['email'],
  }) {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
      isMaker: isMaker,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      providers: providers,
    );
  }

  static StoryEntity createTestStory({
    String id = '1',
    String makerId = '2',
    String title = 'Test Story',
    String description = 'Test Description',
    String category = 'test',
    List<String> tags = const ['test'],
    double minimumOffer = 50.0,
    double buyItNowPrice = 150.0,
  }) {
    return StoryEntity(
      id: id,
      makerId: makerId,
      title: title,
      description: description,
      videoUrl: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      category: category,
      tags: tags,
      minimumOffer: minimumOffer,
      buyItNowPrice: buyItNowPrice,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  }
}
```

### Test Data Factory

```dart
// test/test_helpers/test_data_factory.dart

import 'package:video_window/features/auth/domain/entities/user_entity.dart';
import 'package:video_window/features/feed/domain/entities/story_entity.dart';

class TestDataFactory {
  static UserEntity createUser({
    String id = '1',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool isEmailVerified = true,
    bool isMaker = false,
  }) {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
      isMaker: isMaker,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      providers: ['email'],
    );
  }

  static StoryEntity createStory({
    String id = '1',
    String makerId = '2',
    String title = 'Test Story',
    String description = 'Test Description',
    String category = 'test',
    List<String> tags = const ['test'],
    double minimumOffer = 50.0,
    double buyItNowPrice = 150.0,
  }) {
    return StoryEntity(
      id: id,
      makerId: makerId,
      title: title,
      description: description,
      videoUrl: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      category: category,
      tags: tags,
      minimumOffer: minimumOffer,
      buyItNowPrice: buyItNowPrice,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static List<StoryEntity> createStoryList(int count) {
    return List.generate(count, (index) => createStory(
      id: index.toString(),
      makerId: 'maker_${index % 5}',
      title: 'Story $index',
      description: 'Description for story $index',
    ));
  }

  static List<UserEntity> createUserList(int count) {
    return List.generate(count, (index) => createUser(
      id: index.toString(),
      email: 'user$index@example.com',
      displayName: 'User $index',
      isMaker: index % 2 == 0,
    ));
  }
}
```

## Running Tests

### Test Commands

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/features/auth/bloc/auth_bloc_test.dart

# Run tests in a directory
flutter test test/unit/features/auth/

# Run tests with specific reporter
flutter test --reporter=expanded

# Run tests with specific name pattern
flutter test --name="Authentication"

# Run tests excluding golden tests
flutter test --exclude-tags=golden

# Run tests on specific platform
flutter test --platform=chrome
```

### Coverage Report

```bash
# Generate coverage report
flutter test --coverage

# Convert coverage to HTML
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
open coverage/html/index.html
```

---

**Last Updated:** 2025-10-09
**Related Documentation:** [Testing Strategy](testing-strategy.md) | [Integration Testing](integration-testing-guide.md) | [Widget Testing](widget-testing-guide.md)