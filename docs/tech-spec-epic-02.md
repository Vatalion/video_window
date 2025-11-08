# Epic 02: Core Platform Services - Technical Specification

**Epic Goal:** Establish foundational platform services including design system, navigation infrastructure, configuration management, and analytics foundation to enable consistent and scalable feature development.

**Stories:**
- 02-1: Design System & Theme Foundation
- 02-2: Navigation Infrastructure & Routing
- 02-3: Configuration Management & Feature Flags
- 02-4: Analytics Service Foundation

---

## Architecture Overview

### Component Mapping
- **Design System:** Shared package with design tokens, theme, typography
- **Navigation:** go_router with type-safe routing and deep linking
- **Configuration:** Environment-based config with feature flags
- **Analytics:** Event tracking foundation with BigQuery integration
- **Shared Widgets:** Reusable UI components library

### Technology Stack
- **Flutter:** 3.35.4+ (minimum 3.19.6)
- **go_router:** 12.1.3+ for declarative navigation
- **shared_preferences:** Configuration persistence
- **Analytics:** Custom event service + BigQuery
- **Design Tokens:** Custom JSON-based token system
- **State Management:** flutter_bloc for navigation state

---

## Design System Architecture

### Design Token Structure

**File:** `video_window_flutter/packages/shared/lib/design_system/tokens.dart`

```dart
// Color Tokens
class AppColors {
  // Brand Colors
  static const primary = Color(0xFF6366F1);      // Indigo-500
  static const primaryDark = Color(0xFF4F46E5);  // Indigo-600
  static const primaryLight = Color(0xFF818CF8); // Indigo-400
  
  // Semantic Colors
  static const success = Color(0xFF10B981);      // Green-500
  static const warning = Color(0xFFF59E0B);      // Amber-500
  static const error = Color(0xFFEF4444);        // Red-500
  static const info = Color(0xFF3B82F6);         // Blue-500
  
  // Neutral Colors
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral500 = Color(0xFF737373);
  static const neutral600 = Color(0xFF525252);
  static const neutral700 = Color(0xFF404040);
  static const neutral800 = Color(0xFF262626);
  static const neutral900 = Color(0xFF171717);
  
  // Surface Colors
  static const surface = Colors.white;
  static const surfaceDark = Color(0xFF1F2937);
  static const background = Color(0xFFFAFAFA);
  static const backgroundDark = Color(0xFF111827);
}

// Typography Tokens
class AppTypography {
  static const fontFamily = 'Inter';
  
  // Display Styles
  static const displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.25,
  );
  
  static const displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
  );
  
  static const displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.22,
  );
  
  // Headline Styles
  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  
  static const headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
  );
  
  static const headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );
  
  // Body Styles
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  // Label Styles
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );
}

// Spacing Tokens
class AppSpacing {
  static const xxxs = 2.0;
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

// Border Radius Tokens
class AppRadius {
  static const none = 0.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 9999.0;
}

// Elevation Tokens
class AppElevation {
  static const none = 0.0;
  static const xs = 1.0;
  static const sm = 2.0;
  static const md = 4.0;
  static const lg = 8.0;
  static const xl = 16.0;
}
```

### Theme Configuration

**File:** `video_window_flutter/packages/shared/lib/design_system/theme.dart`

```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.neutral900,
      background: AppColors.background,
      onBackground: AppColors.neutral900,
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.neutral900,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: AppElevation.sm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.neutral50,
      background: AppColors.backgroundDark,
      onBackground: AppColors.neutral50,
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.neutral50),
      displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.neutral50),
      displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.neutral50),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.neutral50),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.neutral50),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.neutral50),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.neutral100),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.neutral100),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.neutral200),
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
  );
}
```

---

## Navigation Architecture

### go_router Configuration

**File:** `video_window_flutter/lib/app_shell/router.dart`

```dart
final goRouter = GoRouter(
  initialLocation: '/feed',
  debugLogDiagnostics: true,
  routes: [
    // Authentication Routes
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthPage(),
      routes: [
        GoRoute(
          path: 'sign-in',
          name: 'sign-in',
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: 'sign-up',
          name: 'sign-up',
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: 'recovery',
          name: 'recovery',
          builder: (context, state) => const RecoveryPage(),
        ),
      ],
    ),
    
    // Main App Routes
    GoRoute(
      path: '/feed',
      name: 'feed',
      builder: (context, state) => const FeedPage(),
    ),
    
    GoRoute(
      path: '/story/:storyId',
      name: 'story-detail',
      builder: (context, state) {
        final storyId = state.pathParameters['storyId']!;
        return StoryDetailPage(storyId: storyId);
      },
    ),
    
    // Maker Routes
    GoRoute(
      path: '/create',
      name: 'create',
      builder: (context, state) => const CreateStoryPage(),
    ),
    
    GoRoute(
      path: '/publish/:draftId',
      name: 'publish',
      builder: (context, state) {
        final draftId = state.pathParameters['draftId']!;
        return PublishPage(draftId: draftId);
      },
    ),
    
    // Commerce Routes
    GoRoute(
      path: '/auction/:auctionId',
      name: 'auction',
      builder: (context, state) {
        final auctionId = state.pathParameters['auctionId']!;
        return AuctionPage(auctionId: auctionId);
      },
    ),
    
    GoRoute(
      path: '/checkout/:offerId',
      name: 'checkout',
      builder: (context, state) {
        final offerId = state.pathParameters['offerId']!;
        return CheckoutPage(offerId: offerId);
      },
    ),
    
    // Profile Routes
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
      routes: [
        GoRoute(
          path: 'settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: 'orders',
          name: 'orders',
          builder: (context, state) => const OrdersPage(),
        ),
      ],
    ),
    
    // Error Route
    GoRoute(
      path: '/error',
      name: 'error',
      builder: (context, state) {
        final error = state.extra as String?;
        return ErrorPage(message: error);
      },
    ),
  ],
  
  // Redirect logic for authentication
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState is AuthAuthenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    
    if (!isAuthenticated && !isAuthRoute) {
      return '/auth/sign-in';
    }
    
    if (isAuthenticated && isAuthRoute) {
      return '/feed';
    }
    
    return null;
  },
  
  // Error handling
  errorBuilder: (context, state) => ErrorPage(
    message: state.error?.toString() ?? 'Unknown error',
  ),
);
```

### Type-Safe Navigation Extensions

**File:** `video_window_flutter/lib/app_shell/navigation_extensions.dart`

```dart
extension NavigationExtensions on BuildContext {
  // Authentication
  void goToSignIn() => go('/auth/sign-in');
  void goToSignUp() => go('/auth/sign-up');
  void goToRecovery() => go('/auth/recovery');
  
  // Main Routes
  void goToFeed() => go('/feed');
  void goToStoryDetail(String storyId) => go('/story/$storyId');
  
  // Maker Routes
  void goToCreate() => go('/create');
  void goToPublish(String draftId) => go('/publish/$draftId');
  
  // Commerce Routes
  void goToAuction(String auctionId) => go('/auction/$auctionId');
  void goToCheckout(String offerId) => go('/checkout/$offerId');
  
  // Profile Routes
  void goToProfile() => go('/profile');
  void goToSettings() => go('/profile/settings');
  void goToOrders() => go('/profile/orders');
  
  // Error handling
  void goToError(String message) => go('/error', extra: message);
}
```

---

## Configuration Management

### Environment Configuration

**File:** `video_window_flutter/lib/app_shell/config.dart`

```dart
enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String cdnBaseUrl;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enableDebugLogging;
  final Map<String, bool> featureFlags;
  
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.cdnBaseUrl,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.enableDebugLogging,
    required this.featureFlags,
  });
  
  factory AppConfig.development() => AppConfig(
    environment: Environment.development,
    apiBaseUrl: 'http://localhost:8080',
    cdnBaseUrl: 'http://localhost:8080/cdn',
    enableAnalytics: false,
    enableCrashReporting: false,
    enableDebugLogging: true,
    featureFlags: {
      'social_login': true,
      'video_upload': true,
      'auction_bidding': true,
      'push_notifications': false,
    },
  );
  
  factory AppConfig.staging() => AppConfig(
    environment: Environment.staging,
    apiBaseUrl: 'https://api-staging.craftvideomarketplace.com',
    cdnBaseUrl: 'https://cdn-staging.craftvideomarketplace.com',
    enableAnalytics: true,
    enableCrashReporting: true,
    enableDebugLogging: true,
    featureFlags: {
      'social_login': true,
      'video_upload': true,
      'auction_bidding': true,
      'push_notifications': true,
    },
  );
  
  factory AppConfig.production() => AppConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://api.craftvideomarketplace.com',
    cdnBaseUrl: 'https://cdn.craftvideomarketplace.com',
    enableAnalytics: true,
    enableCrashReporting: true,
    enableDebugLogging: false,
    featureFlags: {
      'social_login': true,
      'video_upload': true,
      'auction_bidding': true,
      'push_notifications': true,
    },
  );
  
  bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }
}
```

---

## Analytics Service Foundation

### Event Tracking Architecture

**File:** `video_window_flutter/packages/core/lib/services/analytics_service.dart`

```dart
abstract class AnalyticsEvent {
  String get name;
  Map<String, dynamic> get properties;
  DateTime get timestamp;
}

class AnalyticsService {
  final AppConfig _config;
  final List<AnalyticsEvent> _eventQueue = [];
  
  AnalyticsService(this._config);
  
  Future<void> trackEvent(AnalyticsEvent event) async {
    if (!_config.enableAnalytics) return;
    
    _eventQueue.add(event);
    
    // Batch events for efficiency
    if (_eventQueue.length >= 10) {
      await _flushEvents();
    }
  }
  
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty) return;
    
    try {
      // Send to BigQuery or analytics backend
      final events = _eventQueue.map((e) => {
        'name': e.name,
        'properties': e.properties,
        'timestamp': e.timestamp.toIso8601String(),
      }).toList();
      
      // TODO: Implement actual BigQuery integration
      print('Analytics: Flushing ${events.length} events');
      
      _eventQueue.clear();
    } catch (e) {
      print('Analytics error: $e');
    }
  }
  
  Future<void> dispose() async {
    await _flushEvents();
  }
}

// Common Events
class ScreenViewEvent extends AnalyticsEvent {
  final String screenName;
  
  ScreenViewEvent(this.screenName);
  
  @override
  String get name => 'screen_view';
  
  @override
  Map<String, dynamic> get properties => {'screen_name': screenName};
  
  @override
  DateTime get timestamp => DateTime.now();
}

class UserActionEvent extends AnalyticsEvent {
  final String action;
  final Map<String, dynamic> context;
  
  UserActionEvent(this.action, {this.context = const {}});
  
  @override
  String get name => 'user_action';
  
  @override
  Map<String, dynamic> get properties => {
    'action': action,
    ...context,
  };
  
  @override
  DateTime get timestamp => DateTime.now();
}
```

---

## Shared Widget Library

### Common Components

**File:** `video_window_flutter/packages/shared/lib/widgets/`

```dart
// Loading Indicator
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  
  const AppLoadingIndicator({this.message, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            SizedBox(height: AppSpacing.md),
            Text(message!, style: AppTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// Error View
class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const AppErrorView({
    required this.message,
    this.onRetry,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onRetry,
                child: Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Primary Button
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  
  const AppPrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(label),
    );
  }
}
```

---

## Success Criteria

Epic 02 is considered complete when:

- ✅ Design system tokens defined and documented
- ✅ Light and dark themes implemented
- ✅ go_router configured with all main routes
- ✅ Type-safe navigation extensions created
- ✅ Environment configuration with feature flags
- ✅ Analytics service foundation implemented
- ✅ Shared widget library with common components
- ✅ All components follow design system tokens
- ✅ Navigation includes authentication guards
- ✅ Configuration can be loaded per environment

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-03  
**Status:** APPROVED  
**Approved By:** Winston (Architect), Sally (UX Designer), Amelia (Dev Lead)  
**Approval Date:** 2025-11-03
