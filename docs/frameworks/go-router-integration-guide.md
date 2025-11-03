# go_router Integration Guide - Video Window

**Version:** go_router 16.3.0 (using 12.1.3 in project)  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Core Navigation Foundation

---

## Overview

**go_router** is Flutter's declarative routing package built on Navigation 2.0. It provides URL-based navigation, deep linking, route guards, and type-safe routing for Video Window's mobile app.

### Why go_router in Video Window?

- **Deep Linking:** Handle `videowindow://story/123` URLs from notifications
- **Declarative Routes:** Define all routes in one place with hierarchies
- **Route Guards:** Protect authenticated routes (profile, offers, auctions)
- **Type-Safe Navigation:** Generate type-safe route classes
- **Web Support:** URL-based navigation ready for future web expansion
- **State Restoration:** Preserve navigation state across app restarts

### Architecture Role

```
App → GoRouter → Routes → Screens
          ↓
    Route Guards (auth check)
          ↓
    Deep Links (notifications)
```

---

## Installation

```yaml
# video_window_flutter/pubspec.yaml
dependencies:
  go_router: ^12.1.3  # Declarative navigation
```

---

## Video Window Route Structure

### Route Hierarchy

```
/                           # Feed (timeline of stories)
├── /story/:id              # Story detail page
│   └── /story/:id/offer    # Create offer modal
├── /search                 # Search stories
├── /profile                # User profile (auth required)
│   ├── /profile/edit       # Edit profile
│   └── /profile/offers     # My offers
├── /auctions               # Active auctions (auth required)
│   └── /auctions/:id       # Auction detail
├── /orders                 # Order history (auth required)
│   └── /orders/:id         # Order detail & tracking
├── /settings               # App settings
└── /auth                   # Authentication flow
    ├── /auth/signin        # Sign in
    └── /auth/signup        # Sign up
```

---

## Pattern 1: Router Configuration

```dart
// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/bloc/auth/auth_bloc.dart';

class AppRouter {
  final AuthBloc authBloc;
  
  AppRouter(this.authBloc);
  
  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,  // Enable in dev only
    initialLocation: '/',
    
    // Redirect logic (auth guard)
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is Authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      
      // Redirect to auth if not authenticated and accessing protected route
      if (!isAuthenticated && !isAuthRoute && _requiresAuth(state.matchedLocation)) {
        return '/auth/signin?redirect=${state.matchedLocation}';
      }
      
      // Redirect away from auth if already authenticated
      if (isAuthenticated && isAuthRoute) {
        final redirect = state.uri.queryParameters['redirect'];
        return redirect ?? '/';
      }
      
      return null;  // No redirect
    },
    
    // Listen to auth state changes
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    
    routes: [
      // Public routes
      GoRoute(
        path: '/',
        name: 'feed',
        builder: (context, state) => const FeedPage(),
        routes: [
          GoRoute(
            path: 'story/:id',
            name: 'story',
            builder: (context, state) {
              final storyId = state.pathParameters['id']!;
              return StoryPage(storyId: storyId);
            },
            routes: [
              GoRoute(
                path: 'offer',
                name: 'createOffer',
                pageBuilder: (context, state) {
                  final storyId = state.pathParameters['id']!;
                  return MaterialPage(
                    fullscreenDialog: true,
                    child: CreateOfferPage(storyId: storyId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'search',
            name: 'search',
            builder: (context, state) {
              final query = state.uri.queryParameters['q'] ?? '';
              return SearchPage(initialQuery: query);
            },
          ),
        ],
      ),
      
      // Auth routes
      GoRoute(
        path: '/auth/signin',
        name: 'signin',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      
      // Protected routes (require auth)
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'editProfile',
            builder: (context, state) => const EditProfilePage(),
          ),
          GoRoute(
            path: 'offers',
            name: 'myOffers',
            builder: (context, state) => const MyOffersPage(),
          ),
        ],
      ),
      
      GoRoute(
        path: '/auctions',
        name: 'auctions',
        builder: (context, state) => const AuctionsPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'auctionDetail',
            builder: (context, state) {
              final auctionId = state.pathParameters['id']!;
              return AuctionDetailPage(auctionId: auctionId);
            },
          ),
        ],
      ),
      
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'orderDetail',
            builder: (context, state) {
              final orderId = state.pathParameters['id']!;
              return OrderDetailPage(orderId: orderId);
            },
          ),
        ],
      ),
      
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => ErrorPage(
      error: state.error,
      location: state.matchedLocation,
    ),
  );
  
  bool _requiresAuth(String location) {
    const protectedPaths = ['/profile', '/auctions', '/orders'];
    return protectedPaths.any((path) => location.startsWith(path));
  }
}

// Helper for auth state stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  
  late final StreamSubscription<dynamic> _subscription;
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

---

## Pattern 2: Using Router in Main App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'router/app_router.dart';
import 'presentation/bloc/auth/auth_bloc.dart';

void main() {
  // Initialize dependencies
  final authBloc = AuthBloc(/* dependencies */);
  final appRouter = AppRouter(authBloc);
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        // Other BLoCs...
      ],
      child: MyApp(router: appRouter),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppRouter router;
  
  const MyApp({required this.router, super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Video Window',
      theme: ThemeData(/* theme */),
      routerConfig: router.router,  // Pass GoRouter config
    );
  }
}
```

---

## Pattern 3: Navigation (Imperative)

```dart
// Navigate to routes
context.go('/story/123');                    // Replace current route
context.push('/profile');                    // Push onto stack
context.pop();                               // Go back

// With query parameters
context.go('/search?q=crafts');

// Named routes
context.goNamed('story', pathParameters: {'id': '123'});
context.pushNamed('createOffer', 
  pathParameters: {'id': '123'},
  queryParameters: {'amount': '50'},
);

// Replace (no back button)
context.pushReplacement('/auth/signin');
```

---

## Pattern 4: Deep Linking

### Configure Deep Links (iOS)

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>dev.videowindow.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>videowindow</string>
    </array>
  </dict>
</array>
```

### Configure Deep Links (Android)

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity android:name=".MainActivity">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Deep link: videowindow://story/123 -->
    <data
      android:scheme="videowindow"
      android:host="story" />
    <!-- Universal link: https://videowindow.app/story/123 -->
    <data
      android:scheme="https"
      android:host="videowindow.app" />
  </intent-filter>
</activity>
```

### Handle Deep Links

```dart
// go_router automatically handles deep links!
// No additional code needed - routes match URLs

// Example: videowindow://story/123 → StoryPage(storyId: '123')
// Example: videowindow://auth/signin → SignInPage()
```

---

## Pattern 5: Route Guards (Authentication)

```dart
// Already configured in router redirect callback
redirect: (context, state) {
  final authState = authBloc.state;
  final isAuthenticated = authState is Authenticated;
  final isAuthRoute = state.matchedLocation.startsWith('/auth');
  
  // Guard protected routes
  if (!isAuthenticated && _requiresAuth(state.matchedLocation)) {
    return '/auth/signin?redirect=${state.matchedLocation}';
  }
  
  // After signin, redirect to original destination
  if (isAuthenticated && isAuthRoute) {
    final redirect = state.uri.queryParameters['redirect'];
    return redirect ?? '/';
  }
  
  return null;
},
```

---

## Pattern 6: Nested Navigation (ShellRoute)

For bottom navigation bar that persists across screens:

```dart
ShellRoute(
  builder: (context, state, child) {
    return ScaffoldWithNavBar(child: child);
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FeedPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
),
```

---

## Pattern 7: Modal Routes

```dart
GoRoute(
  path: 'offer',
  name: 'createOffer',
  pageBuilder: (context, state) {
    return MaterialPage(
      fullscreenDialog: true,  // Show as modal
      child: CreateOfferPage(storyId: state.pathParameters['id']!),
    );
  },
),
```

---

## Testing Routes

```dart
// packages/video_window_flutter/test/router/app_router_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MockAuthBloc mockAuthBloc;
  late AppRouter appRouter;
  
  setUp(() {
    mockAuthBloc = MockAuthBloc();
    appRouter = AppRouter(mockAuthBloc);
  });
  
  group('Route Guards', () {
    test('redirects to signin when accessing profile while unauthenticated', () {
      when(() => mockAuthBloc.state).thenReturn(Unauthenticated());
      
      final redirect = appRouter.router.routerDelegate.redirect(
        MockBuildContext(),
        GoRouterState(uri: Uri.parse('/profile'), matchedLocation: '/profile'),
      );
      
      expect(redirect, '/auth/signin?redirect=/profile');
    });
    
    test('allows access to profile when authenticated', () {
      when(() => mockAuthBloc.state).thenReturn(Authenticated(mockUser));
      
      final redirect = appRouter.router.routerDelegate.redirect(
        MockBuildContext(),
        GoRouterState(uri: Uri.parse('/profile'), matchedLocation: '/profile'),
      );
      
      expect(redirect, isNull);  // No redirect = allowed
    });
  });
}
```

---

## Common Issues & Solutions

### Issue 1: "No GoRouter found in context"

```dart
// ❌ WRONG - Called before MaterialApp.router
void main() {
  runApp(const MyApp());
  context.go('/home');  // No context yet!
}

// ✅ CORRECT - Use within widget tree
ElevatedButton(
  onPressed: () => context.go('/profile'),
  child: const Text('Profile'),
)
```

---

### Issue 2: Infinite Redirect Loop

```dart
// ❌ WRONG - Always redirects
redirect: (context, state) {
  return '/auth/signin';  // Always redirects!
},

// ✅ CORRECT - Conditional redirect
redirect: (context, state) {
  if (!isAuthenticated && state.matchedLocation != '/auth/signin') {
    return '/auth/signin';
  }
  return null;
},
```

---

## Video Window Conventions

### Route Naming
- **Paths:** `/lowercase-with-hyphens`
- **Names:** `camelCase` (e.g., `'createOffer'`)
- **Parameters:** `:snakeCase` (e.g., `:story_id`)

### Navigation Patterns
- **Push for modals:** `context.push('/path')`
- **Go for tab switches:** `context.go('/path')`
- **Pop for back:** `context.pop()` or `Navigator.pop(context)`

### Error Handling
- Always provide `errorBuilder` for 404/errors
- Log navigation events in debug mode
- Show user-friendly error pages

---

## Reference

- **Package:** https://pub.dev/packages/go_router
- **Documentation:** https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html
- **Version Used:** 12.1.3 (latest stable: 16.3.0)

### Related Guides
- **BLoC Integration:** `bloc-integration-guide.md`
- **Deep Linking:** `docs/architecture/deep-linking.md`

---

**Last Updated:** 2025-11-03 by Winston (Architect)  
**Verified Against:** go_router 16.3.0 documentation  
**Next Review:** On go_router major version upgrade

---

**Change Log:**

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-03 | v1.0 | Initial integration guide for Video Window | Winston |
