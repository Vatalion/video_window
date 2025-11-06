import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation service abstraction providing a testable interface for routing.
///
/// Wraps [GoRouter] functionality to enable:
/// - Dependency injection of navigation logic
/// - Easy mocking in tests
/// - Centralized navigation analytics
/// - Route change logging
///
/// Usage:
/// ```dart
/// class MyBloc {
///   MyBloc(this._navigation);
///
///   final NavigationService _navigation;
///
///   void navigateToStory(String id) {
///     _navigation.pushNamed('storyDetail', pathParameters: {'id': id});
///   }
/// }
/// ```
abstract class NavigationService {
  /// Navigates to a location using path.
  ///
  /// Example: `go('/story/123')`
  void go(String location, {Object? extra});

  /// Navigates to a named route.
  ///
  /// Example: `goNamed('storyDetail', pathParameters: {'id': '123'})`
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  });

  /// Pushes a location onto the navigation stack.
  ///
  /// Returns a Future that completes when the pushed route is popped.
  Future<T?> push<T extends Object?>(String location, {Object? extra});

  /// Pushes a named route onto the navigation stack.
  ///
  /// Returns a Future that completes when the pushed route is popped.
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  });

  /// Pops the top route off the navigation stack.
  ///
  /// Optionally returns [result] to the previous route.
  void pop<T extends Object?>([T? result]);

  /// Replaces the current route with a new location.
  void replace(String location, {Object? extra});

  /// Replaces the current route with a named route.
  void replaceNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  });

  /// Returns whether the navigator can pop.
  bool canPop();

  /// Returns the current location path.
  String get currentLocation;
}

/// Implementation of [NavigationService] using GoRouter.
///
/// This is the production implementation that delegates to [GoRouter]
/// via the Flutter [BuildContext].
class GoRouterNavigationService implements NavigationService {
  GoRouterNavigationService(this._context);

  final BuildContext _context;

  @override
  void go(String location, {Object? extra}) {
    _context.go(location, extra: extra);
  }

  @override
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    _context.goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    return _context.push<T>(location, extra: extra);
  }

  @override
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    return _context.pushNamed<T>(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  @override
  void pop<T extends Object?>([T? result]) {
    _context.pop(result);
  }

  @override
  void replace(String location, {Object? extra}) {
    _context.replace(location, extra: extra);
  }

  @override
  void replaceNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    _context.replaceNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  @override
  bool canPop() {
    return _context.canPop();
  }

  @override
  String get currentLocation {
    return GoRouterState.of(_context).matchedLocation;
  }
}

/// Mock implementation of [NavigationService] for testing.
///
/// Records all navigation calls for verification in tests.
///
/// Usage:
/// ```dart
/// test('should navigate to story detail', () {
///   final mockNav = MockNavigationService();
///   final bloc = MyBloc(mockNav);
///
///   bloc.navigateToStory('123');
///
///   expect(mockNav.pushedRoutes, contains('storyDetail'));
/// });
/// ```
class MockNavigationService implements NavigationService {
  final List<String> goLocations = [];
  final List<String> goNamedCalls = [];
  final List<String> pushedLocations = [];
  final List<String> pushedRoutes = [];
  int popCount = 0;

  @override
  void go(String location, {Object? extra}) {
    goLocations.add(location);
  }

  @override
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    goNamedCalls.add(name);
  }

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async {
    pushedLocations.add(location);
    return null;
  }

  @override
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) async {
    pushedRoutes.add(name);
    return null;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCount++;
  }

  @override
  void replace(String location, {Object? extra}) {
    goLocations.add(location);
  }

  @override
  void replaceNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    goNamedCalls.add(name);
  }

  @override
  bool canPop() => true;

  @override
  String get currentLocation => '/';

  /// Resets all recorded navigation calls
  void reset() {
    goLocations.clear();
    goNamedCalls.clear();
    pushedLocations.clear();
    pushedRoutes.clear();
    popCount = 0;
  }
}
