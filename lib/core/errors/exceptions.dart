/// Base exception class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic innerException;

  const AppException({
    required this.message,
    this.code,
    this.innerException,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Server exceptions
class ServerException extends AppException {
  const ServerException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Network exceptions
class NetworkException extends AppException {
  const NetworkException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Authentication exceptions
class AuthenticationException extends AppException {
  const AuthenticationException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Biometric authentication exceptions
class BiometricException extends AppException {
  const BiometricException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Authorization exceptions
class AuthorizationException extends AppException {
  const AuthorizationException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Shipping exceptions
class ShippingException extends AppException {
  const ShippingException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Address validation exceptions
class AddressValidationException extends AppException {
  const AddressValidationException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}

/// Carrier API exceptions
class CarrierApiException extends AppException {
  const CarrierApiException({
    required String message,
    String? code,
    dynamic innerException,
  }) : super(
          message: message,
          code: code,
          innerException: innerException,
        );
}