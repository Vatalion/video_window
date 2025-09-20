class Failure {
  final String message;
  final String code;
  final dynamic details;

  Failure({
    required this.message,
    required this.code,
    this.details,
  });

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

class ServerFailure extends Failure {
  ServerFailure({
    required String message,
    String code = 'SERVER_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class NetworkFailure extends Failure {
  NetworkFailure({
    required String message,
    String code = 'NETWORK_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class ValidationFailure extends Failure {
  ValidationFailure({
    required String message,
    String code = 'VALIDATION_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class SecurityFailure extends Failure {
  SecurityFailure({
    required String message,
    String code = 'SECURITY_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class AuthenticationFailure extends Failure {
  AuthenticationFailure({
    required String message,
    String code = 'AUTHENTICATION_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class NotFoundFailure extends Failure {
  NotFoundFailure({
    required String message,
    String code = 'NOT_FOUND',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class PermissionFailure extends Failure {
  PermissionFailure({
    required String message,
    String code = 'PERMISSION_DENIED',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

class CacheFailure extends Failure {
  CacheFailure({
    required String message,
    String code = 'CACHE_ERROR',
    dynamic details,
  }) : super(message: message, code: code, details: details);
}