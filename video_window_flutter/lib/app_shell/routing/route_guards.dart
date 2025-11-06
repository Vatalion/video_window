import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:go_router/go_router.dart';
import 'package:video_window_flutter/app_shell/routing/app_routes.dart';

/// Authentication guard for protecting routes that require user authentication.
///
/// Implements [ChangeNotifier] to notify [GoRouter] when authentication state
/// changes, triggering route re-evaluation and redirects.
///
/// Usage:
/// ```dart
/// final authGuard = AuthenticationGuard();
/// final router = AppRouter.createRouter(authGuard: authGuard);
///
/// // Update authentication state
/// authGuard.setAuthenticated(true);
/// ```
class AuthenticationGuard extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  /// Whether the user is currently authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Whether the auth state has been initialized
  /// Used to prevent redirects before auth state is known
  bool get isInitialized => _isInitialized;

  /// Updates the authentication state and notifies listeners.
  ///
  /// This will trigger [GoRouter] to re-evaluate routes and apply redirects.
  void setAuthenticated(bool value) {
    if (_isAuthenticated != value) {
      _isAuthenticated = value;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Marks authentication as initialized without changing the state.
  /// Useful for completing initialization even if user is not authenticated.
  void setInitialized() {
    if (!_isInitialized) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Route redirect logic called by GoRouter.
  ///
  /// Returns:
  /// - `null` if navigation should proceed
  /// - A redirect path if navigation should be blocked
  ///
  /// Redirect rules:
  /// 1. If auth not initialized, don't redirect (wait for init)
  /// 2. If trying to access authenticated route while not authenticated → sign-in
  /// 3. If trying to access sign-in while authenticated → home
  /// 4. Otherwise allow navigation
  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;

    // Don't redirect until auth is initialized
    if (!_isInitialized) {
      return null;
    }

    // Check if the current route requires authentication
    final requiresAuth = AppRoutes.requiresAuth(path);

    // Not authenticated but trying to access protected route → sign-in
    if (requiresAuth && !_isAuthenticated) {
      return AppRoutes.signIn;
    }

    // Authenticated but trying to access sign-in → home
    if (path == AppRoutes.signIn && _isAuthenticated) {
      return AppRoutes.home;
    }

    // Allow navigation
    return null;
  }

  /// Resets the auth guard to unauthenticated state
  void signOut() {
    setAuthenticated(false);
  }
}

/// Interface for route guard implementations.
///
/// Implement this interface to create custom route guards for different
/// access control scenarios (e.g., role-based access, feature flags).
abstract class RouteGuard {
  /// Determines if navigation to the given route should be allowed.
  ///
  /// Returns:
  /// - `true` if navigation is allowed
  /// - `false` if navigation should be blocked
  bool canNavigate(BuildContext context, GoRouterState state);

  /// Returns a redirect path if navigation is blocked.
  ///
  /// Returns `null` if [canNavigate] returns `true`.
  String? getRedirectPath(BuildContext context, GoRouterState state);
}
