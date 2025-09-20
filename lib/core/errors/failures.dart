/// Base failure class for all application failures
abstract class Failure {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'Failure: $message';
}

/// Server failures
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}

/// Authorization failures
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}

/// Shipping failures
class ShippingFailure extends Failure {
  const ShippingFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}

/// Address validation failures
class AddressValidationFailure extends Failure {
  const AddressValidationFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}

/// Carrier API failures
class CarrierApiFailure extends Failure {
  const CarrierApiFailure({
    required String message,
    String? code,
  }) : super(
          message: message,
          code: code,
        );
}