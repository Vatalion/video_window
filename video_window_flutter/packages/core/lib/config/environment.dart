/// Environment enum for runtime environment detection
enum Environment {
  dev,
  staging,
  prod;

  /// Get the current environment based on build flavor
  static Environment get current {
    // In Flutter, we can use compile-time constants or environment variables
    // For now, we'll use const String.fromEnvironment
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

    switch (flavor.toLowerCase()) {
      case 'prod':
      case 'production':
        return Environment.prod;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'dev':
      case 'development':
      default:
        return Environment.dev;
    }
  }

  /// Check if current environment is development
  bool get isDev => this == Environment.dev;

  /// Check if current environment is staging
  bool get isStaging => this == Environment.staging;

  /// Check if current environment is production
  bool get isProd => this == Environment.prod;

  /// Get environment display name
  String get displayName {
    switch (this) {
      case Environment.dev:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.prod:
        return 'Production';
    }
  }
}
