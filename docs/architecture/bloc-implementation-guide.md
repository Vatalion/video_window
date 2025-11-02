# BLoC Implementation Guide

**Effective Date:** 2025-10-10
**Target Framework:** Flutter 3.19.6, BLoC 8.1.6
**Architecture:** Multi-package with Serverpod backend

## Overview

This guide provides comprehensive instructions for implementing BLoC (Business Logic Component) pattern across the Video Window platform. The implementation follows the documented state management architecture from ADR-0007.

## Architecture Overview

### BLoC Foundation Components

The BLoC architecture is built on several core components:

1. **Base Classes** (`packages/core/lib/bloc/`)
   - `BaseBloc` - Foundation for all BLoCs with error handling and logging
   - `BaseListBloc` - For paginated data management
   - `BaseCrudBloc` - For create/read/update/delete operations
   - `ServerpodBloc` - For backend integration

2. **Infrastructure** (`packages/core/lib/bloc/`)
   - `BlocObserver` - Logging and analytics
   - `BlocInjectionService` - Dependency injection
   - `BlocTestUtils` - Testing utilities

3. **Configuration** (`packages/core/lib/bloc/`)
   - `BlocConfig` - Environment-specific settings
   - `BlocArchitecture` - Global initialization

### Package Structure

```
packages/
├── core/                          # BLoC foundation
│   └── lib/bloc/
│       ├── base_bloc.dart         # Base BLoC class
│       ├── base_list_bloc.dart    # List management
│       ├── base_crud_bloc.dart    # CRUD operations
│       ├── serverpod_bloc.dart    # Serverpod integration
│       ├── bloc_observer.dart     # Logging/analytics
│       ├── bloc_injection.dart    # Dependency injection
│       ├── bloc_test_utils.dart   # Testing utilities
│       └── bloc_config.dart       # Configuration
└── features/
    ├── auth/                      # Authentication BLoC
    │   └── lib/bloc/
    │       ├── auth_bloc.dart
    │       ├── auth_event.dart
    │       └── auth_state.dart
    └── [other features]/         # Feature BLoCs
        └── lib/bloc/
            ├── [feature]_bloc.dart
            ├── [feature]_event.dart
            └── [feature]_state.dart
```

## Getting Started

### 1. Initialization

In your main app, initialize the BLoC architecture:

```dart
import 'package:video_window_core/video_window_core.dart';
import 'package:video_window_auth/video_window_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize BLoC architecture
  await BlocArchitecture.initialize(
    config: BlocArchitectureConfig.development,
  );

  // Register authentication BLoC
  final blocService = GetIt.instance<BlocInjectionService>();
  blocService.registerAuthBloc(() => AuthBloc(
    client: ServerpodClient('http://localhost:8080/'),
  ));

  runApp(MyApp());
}
```

### 2. App Configuration

Wrap your app with the BLoC architecture provider:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocArchitectureProvider(
      config: BlocArchitectureConfig.development,
      child: MaterialApp(
        // ... app configuration
      ),
    );
  }
}
```

## Creating a New BLoC

### 1. Extend Base Classes

Choose the appropriate base class for your BLoC:

```dart
// For simple state management
class FeatureBloc extends BaseBloc<FeatureEvent, FeatureState> {
  // Implementation
}

// For list management
class FeatureListBloc extends BaseListBloc<Item, FeatureListEvent> {
  // Implementation
}

// For CRUD operations
class FeatureCrudBloc extends BaseCrudBloc<Item, FeatureCrudEvent> {
  // Implementation
}

// For Serverpod integration
class FeatureBloc extends ServerpodBloc<FeatureEvent, FeatureState> {
  // Implementation
}
```

### 2. Define Events

Create events that extend `BaseEvent`:

```dart
abstract class FeatureEvent extends BaseEvent {}

class LoadDataEvent extends FeatureEvent {
  final String id;
  const LoadDataEvent(this.id);

  @override
  List<Object> get props => [id];
}

class UpdateDataEvent extends FeatureEvent {
  final DataItem item;
  const UpdateDataEvent(this.item);

  @override
  List<Object> get props => [item];
}
```

### 3. Define States

Create states that extend `BaseState`:

```dart
abstract class FeatureState extends BaseState {}

class FeatureInitial extends FeatureState {
  const FeatureInitial();
}

class FeatureLoading extends FeatureState {
  const FeatureLoading();
}

class FeatureLoaded extends FeatureState {
  final DataItem data;
  const FeatureLoaded(this.data);

  @override
  List<Object> get props => [data];
}

class FeatureError extends FeatureState {
  final String message;
  const FeatureError(this.message);

  @override
  List<Object> get props => [message];
}
```

### 4. Implement BLoC Logic

```dart
@singleton
class FeatureBloc extends BaseBloc<FeatureEvent, FeatureState> {
  final FeatureRepository _repository;

  FeatureBloc(this._repository) : super(const FeatureInitial()) {
    on<LoadDataEvent>(_onLoadData);
    on<UpdateDataEvent>(_onUpdateData);
  }

  Future<void> _onLoadData(
    LoadDataEvent event,
    Emitter<FeatureState> emit,
  ) async {
    emit(const FeatureLoading());

    try {
      final data = await _repository.getData(event.id);
      emit(FeatureLoaded(data));
    } catch (error) {
      emit(FeatureError(error.toString()));
    }
  }

  Future<void> _onUpdateData(
    UpdateDataEvent event,
    Emitter<FeatureState> emit,
  ) async {
    try {
      await _repository.updateData(event.item);
      emit(FeatureLoaded(event.item));
    } catch (error) {
      emit(FeatureError(error.toString()));
    }
  }
}
```

## Dependency Injection

### Register BLoCs

Register your BLoCs with the injection service:

```dart
void registerFeatureBlocs(BlocInjectionService blocService) {
  // Simple BLoC
  blocService.registerBloc('feature_bloc', () => FeatureBloc(
    repository: sl<FeatureRepository>(),
  ));

  // BLoC with dependencies
  blocService.registerBlocWithDependencies<FeatureBloc, FeatureRepository>(
    'feature_bloc',
    (repository) => FeatureBloc(repository),
  );

  // Singleton BLoC
  blocService.registerBloc('settings_bloc', () => SettingsBloc(),
    singleton: true);
}
```

### Use in Widgets

```dart
class FeaturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeatureBloc>(
      create: (context) => context.getBloc<FeatureBloc>('feature_bloc'),
      child: FeatureView(),
    );
  }
}

class FeatureView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureBloc, FeatureState>(
      builder: (context, state) {
        if (state is FeatureLoading) {
          return const CircularProgressIndicator();
        }

        if (state is FeatureLoaded) {
          return FeatureDataWidget(data: state.data);
        }

        if (state is FeatureError) {
          return Text('Error: ${state.message}');
        }

        return const SizedBox.shrink();
      },
    );
  }
}
```

## Serverpod Integration

### Serverpod BLoC

For BLoCs that need Serverpod integration:

```dart
class ServerpodFeatureBloc extends ServerpodBloc<FeatureEvent, FeatureState> {
  ServerpodFeatureBloc({required Client client}) : super(client: client);

  Future<void> _onLoadData(
    LoadDataEvent event,
    Emitter<FeatureState> emit,
  ) async {
    emit(const FeatureLoading());

    try {
      final data = await executeServerpodCall(
        () => client.feature.getData(event.id),
      );
      emit(FeatureLoaded(data));
    } catch (error) {
      emit(FeatureError(error.toString()));
    }
  }
}
```

### Real-time Updates

Use real-time subscriptions:

```dart
class RealtimeBloc extends ServerpodBloc<RealtimeEvent, RealtimeState>
    with ServerpodRealtimeMixin<RealtimeEvent, RealtimeState> {

  @override
  void onTransition(Transition<RealtimeEvent, RealtimeState> transition) {
    super.onTransition(transition);

    // Subscribe to real-time updates
    subscribeToChannel<DataUpdate>('feature_updates',
      dataParser: (data) => DataUpdate.fromJson(data),
      onData: (update) {
        add(DataUpdatedEvent(update));
      },
    );
  }
}
```

## Testing

### Unit Tests

Use the provided testing utilities:

```dart
void main() {
  group('FeatureBloc', () {
    late FeatureBloc featureBloc;
    late MockFeatureRepository mockRepository;

    setUp(() {
      mockRepository = MockFeatureRepository();
      featureBloc = FeatureBloc(mockRepository);
    });

    tearDown(() {
      featureBloc.close();
    });

    blocTest<FeatureBloc, FeatureState>(
      'emits [FeatureLoading, FeatureLoaded] when data is loaded successfully',
      setUp: () {
        when(() => mockRepository.getData('123'))
            .thenAnswer((_) async => testData);
      },
      build: () => featureBloc,
      act: (bloc) => bloc.add(const LoadDataEvent('123')),
      expect: () => [
        const FeatureLoading(),
        FeatureLoaded(testData),
      ],
    );

    blocTest<FeatureBloc, FeatureState>(
      'emits [FeatureLoading, FeatureError] when loading fails',
      setUp: () {
        when(() => mockRepository.getData('123'))
            .thenThrow(Exception('Network error'));
      },
      build: () => featureBloc,
      act: (bloc) => bloc.add(const LoadDataEvent('123')),
      expect: () => [
        const FeatureLoading(),
        const FeatureError('Exception: Network error'),
      ],
    );
  });
}
```

### Widget Tests

Test BLoC integration with widgets:

```dart
void main() {
  testWidgets('FeaturePage shows loading and data', (WidgetTester tester) async {
    final mockBloc = MockFeatureBloc();

    whenListen(mockBloc, Stream.fromIterable([
      const FeatureLoading(),
      FeatureLoaded(testData),
    ]));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<FeatureBloc>.value(
          value: mockBloc,
          child: FeaturePage(),
        ),
      ),
    );

    // Should show loading initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Should show data after loading
    expect(find.byType(FeatureDataWidget), findsOneWidget);
  });
}
```

## Best Practices

### 1. Event Naming

- Use descriptive, action-oriented names
- Include requested/success/failure suffixes
- Keep events focused and single-purpose

```dart
// Good
class UserProfileLoadRequestedEvent extends UserProfileEvent {}
class UserProfileLoadedEvent extends UserProfileEvent {}
class UserProfileLoadErrorEvent extends UserProfileEvent {}

// Bad
class UserProfileEvent extends UserProfileEvent {} // Too generic
class LoadUserProfileEvent extends UserProfileEvent {} // Missing suffix
```

### 2. State Management

- Keep state immutable
- Use copyWith for state updates
- Include all relevant data in state

```dart
class UserProfileState extends BaseState {
  final User? user;
  final bool isLoading;
  final String? error;

  const UserProfileState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserProfileState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
```

### 3. Error Handling

- Use AppException for consistent error handling
- Provide user-friendly error messages
- Log technical details for debugging

```dart
Future<void> _onLoadData(LoadDataEvent event, Emitter<FeatureState> emit) async {
  emit(const FeatureLoading());

  try {
    final data = await _repository.getData(event.id);
    emit(FeatureLoaded(data));
  } on ServerpodClientException catch (e) {
    emit(FeatureError(_getUserFriendlyMessage(e)));
  } catch (e) {
    logger.error('Unexpected error loading data', error: e);
    emit(const FeatureError('An unexpected error occurred'));
  }
}
```

### 4. Repository Integration

- Keep BLoC focused on business logic
- Delegate data operations to repositories
- Use dependency injection for testability

```dart
class FeatureBloc extends BaseBloc<FeatureEvent, FeatureState> {
  final FeatureRepository _repository;

  FeatureBloc(this._repository) : super(const FeatureInitial()) {
    on<LoadDataEvent>(_onLoadData);
  }

  Future<void> _onLoadData(LoadDataEvent event, Emitter<FeatureState> emit) async {
    // BLoC handles state management
    emit(const FeatureLoading());

    // Repository handles data operations
    try {
      final data = await _repository.getData(event.id);
      emit(FeatureLoaded(data));
    } catch (error) {
      emit(FeatureError(error.toString()));
    }
  }
}
```

## Performance Optimization

### 1. Event Debouncing

For events that might fire frequently (like search):

```dart
class SearchBloc extends BaseBloc<SearchEvent, SearchState> {
  SearchBloc() : super(const SearchInitial()) {
    on<SearchTextChangedEvent>(_onSearchTextChanged,
      transformer: debounce(const Duration(milliseconds: 500)));
  }

  Future<void> _onSearchTextChanged(
    SearchTextChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    // Perform search
  }
}
```

### 2. State Persistence

Cache data to improve performance:

```dart
class CachedBloc extends BaseBloc<CachedEvent, CachedState> {
  @override
  Future<void> close() {
    // Save state before closing
    _saveStateToCache(state);
    return super.close();
  }

  void _saveStateToCache(CachedState state) {
    // Implementation
  }
}
```

### 3. Lazy Loading

Load data only when needed:

```dart
class LazyLoadBloc extends BaseBloc<LazyLoadEvent, LazyLoadState> {
  @override
  void onTransition(Transition<LazyLoadEvent, LazyLoadState> transition) {
    super.onTransition(transition);

    // Load data only when state is accessed
    if (transition.nextState is LazyLoadInitial) {
      // Schedule data loading
      Future.microtask(() => add(const LoadDataEvent()));
    }
  }
}
```

## Migration Guide

### From Provider to BLoC

1. **Replace ChangeNotifier with BLoC:**

```dart
// Before
class UserModel extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  Future<void> login(String email, String password) async {
    _user = await authService.login(email, password);
    notifyListeners();
  }
}

// After
abstract class AuthEvent extends BaseEvent {}
class LoginRequestedEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginRequestedEvent(this.email, this.password);
}

abstract class AuthState extends BaseState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
}

class AuthBloc extends BaseBloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<LoginRequestedEvent>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(LoginRequestedEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authService.login(event.email, event.password);
      emit(Authenticated(user));
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }
}
```

2. **Update UI Components:**

```dart
// Before
Consumer<UserModel>(
  builder: (context, userModel, child) {
    if (userModel.user == null) {
      return LoginForm();
    }
    return UserProfile(user: userModel.user!);
  },
)

// After
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return const CircularProgressIndicator();
    }
    if (state is Authenticated) {
      return UserProfile(user: state.user);
    }
    return LoginForm();
  },
)
```

## Troubleshooting

### Common Issues

1. **BLoC not updating UI:**
   - Ensure BLoC is properly provided to the widget tree
   - Check that events are being added to the BLoC
   - Verify state transitions are correct

2. **Memory leaks:**
   - Always close BLoCs when they're no longer needed
   - Use `BlocProvider` with proper disposal
   - Cancel stream subscriptions

3. **Performance issues:**
   - Implement event debouncing for frequent events
   - Use lazy loading for expensive operations
   - Consider state persistence for better UX

### Debugging

Enable BLoC logging for development:

```dart
await BlocArchitecture.initialize(
  config: BlocArchitectureConfig(
    enableLogging: true,
    enablePerformanceMonitoring: true,
  ),
);
```

Use the BLoC observer to track state changes:

```dart
Bloc.observer = AppBlocObserver();
```

## Conclusion

This BLoC implementation provides a robust, scalable foundation for state management across the Video Window platform. By following these guidelines and best practices, development teams can create maintainable, testable, and performant applications.

## References

- [BLoC Library Documentation](https://bloclibrary.dev/)
- [Flutter State Management](https://docs.flutter.dev/development/data-and-backend/state-mgmt)
- [Serverpod Documentation](https://serverpod.dev/)
- [ADR-0007: State Management: BLoC Pattern](adr/ADR-0007-state-management.md)