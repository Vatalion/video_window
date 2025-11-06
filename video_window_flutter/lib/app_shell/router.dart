import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_window_flutter/app_shell/routing/app_routes.dart';
import 'package:video_window_flutter/app_shell/routing/route_guards.dart';

/// Application router configuration using GoRouter.
///
/// Provides type-safe routing with deep linking support, authentication guards,
/// and declarative route definitions following Material Design navigation patterns.
///
/// Features:
/// - Type-safe route definitions via [AppRoutes]
/// - Authentication-aware redirects
/// - Deep linking support for iOS/Android
/// - Route guards for protected content
/// - Error handling for invalid routes
///
/// Usage:
/// ```dart
/// MaterialApp.router(
///   routerConfig: AppRouter.createRouter(authGuard: myAuthGuard),
/// )
/// ```
class AppRouter {
  AppRouter._(); // Private constructor to prevent instantiation

  /// Creates the app router with optional authentication guard.
  ///
  /// [authGuard] - Optional guard to protect authenticated routes.
  /// If not provided, all routes are accessible without authentication.
  static GoRouter createRouter({AuthenticationGuard? authGuard}) {
    return GoRouter(
      initialLocation: AppRoutes.home,
      routes: _buildRoutes(),
      redirect: authGuard?.redirect,
      refreshListenable: authGuard,
      errorBuilder: _buildErrorPage,
      debugLogDiagnostics: true, // Enable logging in debug mode
    );
  }

  /// Builds the complete route tree for the application.
  static List<RouteBase> _buildRoutes() {
    return [
      // Home / Feed route
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (context, state) => const _PlaceholderHomePage(),
      ),

      // Authentication routes
      GoRoute(
        path: AppRoutes.signIn,
        name: AppRoutes.signInName,
        builder: (context, state) => const _PlaceholderSignInPage(),
      ),

      // Story detail route (deep linkable)
      GoRoute(
        path: AppRoutes.storyDetail,
        name: AppRoutes.storyDetailName,
        builder: (context, state) {
          final storyId = state.pathParameters['id'];
          if (storyId == null) {
            return const _ErrorPage(message: 'Story ID is required');
          }
          return _PlaceholderStoryDetailPage(storyId: storyId);
        },
      ),

      // Offer detail route (deep linkable)
      GoRoute(
        path: AppRoutes.offerDetail,
        name: AppRoutes.offerDetailName,
        builder: (context, state) {
          final offerId = state.pathParameters['id'];
          if (offerId == null) {
            return const _ErrorPage(message: 'Offer ID is required');
          }
          return _PlaceholderOfferDetailPage(offerId: offerId);
        },
      ),

      // Profile route (authenticated)
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        builder: (context, state) => const _PlaceholderProfilePage(),
      ),

      // Settings route
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (context, state) => const _PlaceholderSettingsPage(),
      ),

      // Design catalog route (development only)
      GoRoute(
        path: AppRoutes.designCatalog,
        name: AppRoutes.designCatalogName,
        builder: (context, state) => const _PlaceholderDesignCatalogPage(),
      ),
    ];
  }

  /// Builds the error page for invalid routes.
  static Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    return _ErrorPage(
      message: 'Route not found: ${state.uri}',
      uri: state.uri.toString(),
    );
  }
}

// ============================================================================
// PLACEHOLDER PAGES
// These will be replaced with actual feature implementations
// ============================================================================

/// Placeholder home page - to be replaced with actual feed implementation
class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Craft Video Marketplace'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 64),
            SizedBox(height: 16),
            Text(
              'Welcome to Craft Video Marketplace',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Foundation infrastructure ready'),
          ],
        ),
      ),
    );
  }
}

/// Placeholder sign-in page
class _PlaceholderSignInPage extends StatelessWidget {
  const _PlaceholderSignInPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: const Center(child: Text('Sign In Page (Coming Soon)')),
    );
  }
}

/// Placeholder story detail page with ID parameter
class _PlaceholderStoryDetailPage extends StatelessWidget {
  const _PlaceholderStoryDetailPage({required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story Detail')),
      body: Center(child: Text('Story ID: $storyId (Coming Soon)')),
    );
  }
}

/// Placeholder offer detail page with ID parameter
class _PlaceholderOfferDetailPage extends StatelessWidget {
  const _PlaceholderOfferDetailPage({required this.offerId});

  final String offerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer Detail')),
      body: Center(child: Text('Offer ID: $offerId (Coming Soon)')),
    );
  }
}

/// Placeholder profile page (authenticated)
class _PlaceholderProfilePage extends StatelessWidget {
  const _PlaceholderProfilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page (Coming Soon)')),
    );
  }
}

/// Placeholder settings page
class _PlaceholderSettingsPage extends StatelessWidget {
  const _PlaceholderSettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page (Coming Soon)')),
    );
  }
}

/// Placeholder design catalog page
class _PlaceholderDesignCatalogPage extends StatelessWidget {
  const _PlaceholderDesignCatalogPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design Catalog')),
      body: const Center(child: Text('Design Catalog Page (Coming Soon)')),
    );
  }
}

/// Error page for invalid routes
class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.message, this.uri});

  final String message;
  final String? uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (uri != null) ...[
              const SizedBox(height: 8),
              Text(
                uri!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
