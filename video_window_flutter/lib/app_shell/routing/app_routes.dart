/// Type-safe route definitions for the Video Window application.
///
/// Provides compile-time safety for route paths and names, preventing
/// string-based routing errors. All routes are defined as constants to ensure
/// consistency across the application.
///
/// Usage:
/// ```dart
/// context.goNamed(AppRoutes.homeName);
/// context.go(AppRoutes.storyDetail.replaceFirst(':id', storyId));
/// ```
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  // ============================================================================
  // PUBLIC ROUTES
  // ============================================================================

  /// Home / Feed route - Main video feed
  static const String home = '/';
  static const String homeName = 'home';

  /// Sign In route - Authentication screen
  static const String signIn = '/sign-in';
  static const String signInName = 'signIn';

  /// Settings route - App settings
  static const String settings = '/settings';
  static const String settingsName = 'settings';

  /// Design Catalog route - Design system showcase (development)
  static const String designCatalog = '/design-catalog';
  static const String designCatalogName = 'designCatalog';

  // ============================================================================
  // DEEP LINKABLE ROUTES
  // ============================================================================

  /// Story Detail route - Individual story view
  /// Path parameter: :id
  static const String storyDetail = '/story/:id';
  static const String storyDetailName = 'storyDetail';

  /// Offer Detail route - Auction/offer view
  /// Path parameter: :id
  static const String offerDetail = '/offer/:id';
  static const String offerDetailName = 'offerDetail';

  // ============================================================================
  // AUTHENTICATED ROUTES
  // ============================================================================

  /// User Profile route - Requires authentication
  static const String profile = '/profile';
  static const String profileName = 'profile';

  // ============================================================================
  // DEEP LINK SCHEMES
  // ============================================================================

  /// Deep link scheme for iOS and Android
  /// Format: videowindow://story/123
  static const String deepLinkScheme = 'videowindow';

  /// Universal link host for iOS
  /// Format: https://app.videowindow.com/story/123
  static const String universalLinkHost = 'app.videowindow.com';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Builds a story detail path with the given ID
  static String storyDetailPath(String id) => '/story/$id';

  /// Builds an offer detail path with the given ID
  static String offerDetailPath(String id) => '/offer/$id';

  /// Checks if a route requires authentication
  static bool requiresAuth(String path) {
    return path.startsWith(profile);
  }
}
