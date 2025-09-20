/// Application constants
class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';

  // Security
  static const String encryptionKey = 'your-encryption-key-here';
  static const int tokenExpirationMinutes = 60;

  // Address Validation
  static const String smartyStreetsApiKey = 'your-smartystreets-api-key';
  static const String googleMapsApiKey = 'your-google-maps-api-key';

  // Shipping Carriers
  static const String fedexApiKey = 'your-fedex-api-key';
  static const String upsApiKey = 'your-ups-api-key';
  static const String uspsApiKey = 'your-usps-api-key';
  static const String dhlApiKey = 'your-dhl-api-key';

  // Cache
  static const int shippingRateCacheDurationMinutes = 30;
  static const int addressValidationCacheDurationMinutes = 60;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int maxAddressLineLength = 100;
  static const int maxCityLength = 50;
  static const int maxStateLength = 50;
  static const int maxPostalCodeLength = 20;
  static const int maxCountryLength = 50;

  // International Shipping
  static const List<String> supportedCountries = [
    'US', 'CA', 'MX', 'GB', 'DE', 'FR', 'IT', 'ES', 'AU', 'JP',
    'CN', 'IN', 'BR', 'AR', 'CL', 'CO', 'PE', 'RU', 'KR', 'SG'
  ];

  // Timeouts
  static const int networkTimeoutSeconds = 30;
  static const int addressValidationTimeoutSeconds = 10;
  static const int shippingRateCalculationTimeoutSeconds = 15;

  // Security
  static const int maxLoginAttempts = 5;
  static const int accountLockoutDurationMinutes = 15;

  // Shipping
  static const double defaultWeight = 1.0;
  static const double defaultLength = 10.0;
  static const double defaultWidth = 10.0;
  static const double defaultHeight = 10.0;

  // International
  static const double maxPackageWeightKg = 30.0;
  static const double maxPackageLengthCm = 150.0;
  static const double maxPackageWidthCm = 150.0;
  static const double maxPackageHeightCm = 150.0;
}