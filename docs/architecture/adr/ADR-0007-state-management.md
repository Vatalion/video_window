# ADR-0007: State Management: BLoC Pattern

**Date:** 2025-10-09
**Status:** Accepted
**Decider(s):** Technical Lead, Flutter Team Lead
**Reviewers:** Development Team, QA Team

## Context
The Flutter frontend requires a robust state management solution that can handle:
- Real-time auction updates
- Complex user authentication flows
- Payment processing states
- Video upload and processing status
- Responsive UI updates
- Testability and maintainability
- Team collaboration

## Decision
Implement the BLoC (Business Logic Component) pattern using the flutter_bloc package for centralized state management.

## Options Considered

1. **Option A** - setState with StatefulWidget
   - Pros: Simple, built-in to Flutter
   - Cons: Difficult to manage complex state, no separation of concerns
   - Risk: Spaghetti code, difficult testing

2. **Option B** - Provider + ChangeNotifier
   - Pros: Simple dependency injection, good for simple state
   - Cons: Limited for complex state logic, boilerplate
   - Risk: State management complexity at scale

3. **Option C** - Riverpod
   - Pros: Modern, compile-time safety, flexible
   - Cons: Learning curve, smaller community than BLoC
   - Risk: Team adoption challenges

4. **Option D** - BLoC Pattern (Chosen)
   - Pros: Clear separation of concerns, excellent for complex state, great testing support, mature ecosystem
   - Cons: More boilerplate, learning curve
   - Risk: Over-engineering for simple cases

## Decision Outcome
Chose Option D: BLoC Pattern. This provides:
- Clear separation of business logic and UI
- Excellent testability
- Predictable state transitions
- Great tooling and debugging
- Mature ecosystem and community
- Real-time state synchronization

## Consequences

- **Positive:**
  - Clear separation of concerns
  - Excellent testability
  - Predictable state management
  - Great debugging and tooling
  - Strong community support
  - Real-time state synchronization

- **Negative:**
  - More boilerplate code
  - Learning curve for team
  - Initial development overhead
  - Potential over-engineering for simple features

- **Neutral:**
  - Code organization complexity
  - Development workflow changes
  - Testing requirements

## Architecture Overview

### BLoC Architecture Pattern
```
┌─────────────────────────────────────────────────────────────────┐
│                       UI Layer                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │   Widget    │    │   Widget    │    │   Widget    │        │
│  │             │    │             │    │             │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│           │                   │                   │           │
│           └───────────────────┼───────────────────┘           │
│                               │                               │
├───────────────────────────────┼───────────────────────────────┤
│                               │                               │
│                    ┌─────────────────┐                       │
│                    │  BLoC Provider   │                       │
│                    │                 │                       │
│                    └─────────────────┘                       │
│                               │                               │
├───────────────────────────────┼───────────────────────────────┤
│                               │                               │
│                    ┌─────────────────┐                       │
│                    │      BLoC       │                       │
│                    │                 │                       │
│                    └─────────────────┘                       │
│                               │                               │
├───────────────────────────────┼───────────────────────────────┤
│                               │                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │ Repository  │    │   Service   │    │    API      │        │
│  │             │    │             │    │             │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

### BLoC Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── bloc_providers/
│   │   ├── auth_bloc_provider.dart
│   │   ├── auction_bloc_provider.dart
│   │   └── payment_bloc_provider.dart
│   └── router/
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   ├── auth_state.dart
│   │   │   └── auth_bloc_test.dart
│   │   ├── view/
│   │   │   ├── login_page.dart
│   │   │   ├── register_page.dart
│   │   │   └── widgets/
│   │   └── data/
│   │       ├── repositories/
│   │       └── models/
│   ├── auctions/
│   │   ├── bloc/
│   │   │   ├── auction_bloc.dart
│   │   │   ├── auction_event.dart
│   │   │   ├── auction_state.dart
│   │   │   └── auction_bloc_test.dart
│   │   ├── view/
│   │   └── data/
│   └── payments/
│       ├── bloc/
│       ├── view/
│       └── data/
└── shared/
    ├── widgets/
    ├── models/
    └── utils/
```

## Implementation Examples

### Auth BLoC Implementation
```dart
// auth_event.dart
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;

  const RegisterRequested(this.email, this.password, this.username);

  @override
  List<Object> get props => [email, password, username];
}

class LogoutRequested extends AuthEvent {}

class AuthStatusChanged extends AuthEvent {
  final AuthStatus status;

  const AuthStatusChanged(this.status);

  @override
  List<Object> get props => [status];
}
```

```dart
// auth_state.dart
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
```

```dart
// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        email: event.email,
        password: event.password,
        username: event.username,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(Unauthenticated());
  }

  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.status == AuthStatus.authenticated) {
      final user = await _authRepository.getCurrentUser();
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }
}
```

### Auction BLoC Implementation
```dart
// auction_event.dart
abstract class AuctionEvent extends Equatable {
  const AuctionEvent();

  @override
  List<Object> get props => [];
}

class LoadAuctions extends AuctionEvent {}

class LoadAuctionDetails extends AuctionEvent {
  final String auctionId;

  const LoadAuctionDetails(this.auctionId);

  @override
  List<Object> get props => [auctionId];
}

class PlaceBid extends AuctionEvent {
  final String auctionId;
  final double amount;

  const PlaceBid(this.auctionId, this.amount);

  @override
  List<Object> get props => [auctionId, amount];
}

class AuctionUpdated extends AuctionEvent {
  final Auction auction;

  const AuctionUpdated(this.auction);

  @override
  List<Object> get props => [auction];
}
```

```dart
// auction_bloc.dart
class AuctionBloc extends Bloc<AuctionEvent, AuctionState> {
  final AuctionRepository _auctionRepository;
  final WebSocketService _webSocketService;

  AuctionBloc(this._auctionRepository, this._webSocketService)
      : super(AuctionInitial()) {
    on<LoadAuctions>(_onLoadAuctions);
    on<LoadAuctionDetails>(_onLoadAuctionDetails);
    on<PlaceBid>(_onPlaceBid);
    on<AuctionUpdated>(_onAuctionUpdated);

    // Listen to WebSocket updates
    _webSocketService.auctionUpdates.listen((auction) {
      add(AuctionUpdated(auction));
    });
  }

  Future<void> _onLoadAuctions(
    LoadAuctions event,
    Emitter<AuctionState> emit,
  ) async {
    emit(AuctionLoading());
    try {
      final auctions = await _auctionRepository.getActiveAuctions();
      emit(AuctionLoaded(auctions));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  Future<void> _onLoadAuctionDetails(
    LoadAuctionDetails event,
    Emitter<AuctionState> emit,
  ) async {
    emit(AuctionLoading());
    try {
      final auction = await _auctionRepository.getAuctionDetails(event.auctionId);
      emit(AuctionDetailLoaded(auction));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  Future<void> _onPlaceBid(
    PlaceBid event,
    Emitter<AuctionState> emit,
  ) async {
    try {
      await _auctionRepository.placeBid(
        auctionId: event.auctionId,
        amount: event.amount,
      );
      // Auction will be updated via WebSocket
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  void _onAuctionUpdated(
    AuctionUpdated event,
    Emitter<AuctionState> emit,
  ) {
    if (state is AuctionLoaded) {
      final auctions = (state as AuctionLoaded).auctions;
      final updatedAuctions = auctions.map((auction) {
        return auction.id == event.auction.id ? event.auction : auction;
      }).toList();
      emit(AuctionLoaded(updatedAuctions));
    } else if (state is AuctionDetailLoaded) {
      emit(AuctionDetailLoaded(event.auction));
    }
  }
}
```

### BLoC Provider Setup
```dart
// auth_bloc_provider.dart
class AuthBlocProvider extends StatelessWidget {
  final Widget child;

  const AuthBlocProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(
        context.read<AuthRepository>(),
      )..add(AuthStatusChanged(AuthStatus.checking)),
      child: child,
    );
  }
}

// auction_bloc_provider.dart
class AuctionBlocProvider extends StatelessWidget {
  final Widget child;

  const AuctionBlocProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuctionBloc(
        context.read<AuctionRepository>(),
        context.read<WebSocketService>(),
      ),
      child: child,
    );
  }
}
```

### UI Integration
```dart
// login_page.dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const CircularProgressIndicator();
            }
            return LoginForm(
              onSubmit: (email, password) {
                context.read<AuthBloc>().add(LoginRequested(email, password));
              },
            );
          },
        ),
      ),
    );
  }
}
```

### Real-time Updates with WebSocket
```dart
// websocket_service.dart
class WebSocketService {
  late final WebSocketChannel _channel;
  final _auctionUpdatesController = StreamController<Auction>.broadcast();

  Stream<Auction> get auctionUpdates => _auctionUpdatesController.stream;

  Future<void> connect() async {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://api.videowindow.com/ws'),
    );

    _channel.stream.listen(
      (message) {
        final data = jsonDecode(message as String);
        if (data['type'] == 'auction_update') {
          final auction = Auction.fromJson(data['auction']);
          _auctionUpdatesController.add(auction);
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
    );
  }

  void subscribeToAuction(String auctionId) {
    _channel.sink.add(jsonEncode({
      'type': 'subscribe_auction',
      'auction_id': auctionId,
    }));
  }
}
```

## Testing Strategy

### BLoC Testing
```dart
// auth_bloc_test.dart
void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('emits Authenticated when login is successful', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password';
      final user = User(id: '1', email: email);

      when(mockAuthRepository.login(email: email, password: password))
          .thenAnswer((_) async => user);

      // Act
      authBloc.add(LoginRequested(email, password));

      // Assert
      expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          Authenticated(user),
        ]),
      );
    });

    test('emits AuthError when login fails', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'wrong_password';

      when(mockAuthRepository.login(email: email, password: password))
          .thenThrow(Exception('Invalid credentials'));

      // Act
      authBloc.add(LoginRequested(email, password));

      // Assert
      expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          AuthError('Exception: Invalid credentials'),
        ]),
      );
    });
  });
}
```

### Widget Testing with BLoC
```dart
// login_page_test.dart
void main() {
  group('LoginPage', () {
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

    testWidgets('shows login form', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('calls login when form is submitted', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password');
      await tester.tap(find.byType(ElevatedButton));

      verify(mockAuthBloc.add(LoginRequested('test@example.com', 'password'))).called(1);
    });
  });
}
```

## Performance Optimization

### BLoC Event Debouncing
```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    on<SearchTextChanged>(_onSearchTextChanged, transformer: debounce(const Duration(milliseconds: 500)));
  }

  Future<void> _onSearchTextChanged(
    SearchTextChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      final results = await performSearch(event.query);
      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}

EventTransformer<Event> debounce<Event>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
}
```

### State Persistence
```dart
class AuctionBloc extends Bloc<AuctionEvent, AuctionState> {
  final AuctionRepository _repository;
  final CacheService _cache;

  AuctionBloc(this._repository, this._cache) : super(AuctionInitial()) {
    on<LoadAuctions>(_onLoadAuctions);
    on<SaveAuctions>(_onSaveAuctions);
  }

  Future<void> _onLoadAuctions(LoadAuctions event, Emitter<AuctionState> emit) async {
    // Try to load from cache first
    final cachedAuctions = await _cache.getAuctions();
    if (cachedAuctions != null) {
      emit(AuctionLoaded(cachedAuctions));
    }

    // Load from network
    try {
      final auctions = await _repository.getActiveAuctions();
      emit(AuctionLoaded(auctions));
      await _cache.saveAuctions(auctions);
    } catch (e) {
      if (state is! AuctionLoaded) {
        emit(AuctionError(e.toString()));
      }
    }
  }
}
```

## Related ADRs
- ADR-0002: Flutter + Serverpod Architecture
- ADR-0006: Modular Monolith with Microservices Migration Path

## References
- [BLoC Library Documentation](https://bloclibrary.dev/)
- [Flutter State Management](https://docs.flutter.dev/development/data-and-backend/state-mgmt)
- [Reactive Programming with Streams](https://dart.dev/guides/libraries/library-tour#stream)

## Status Updates
- **2025-10-09**: Accepted - BLoC pattern for state management confirmed
- **2025-10-09**: BLoC implementation in progress
- **TBD**: Full implementation and team training

---

*This ADR establishes a robust state management architecture using the BLoC pattern, providing excellent separation of concerns, testability, and real-time state synchronization for the video auctions platform.*