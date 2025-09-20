/// Payment-related exceptions for the payment processing system

/// Base exception for all payment-related errors
class PaymentException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  PaymentException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'PaymentException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Network-related exceptions
class NetworkException extends PaymentException {
  final String? url;
  final int? statusCode;

  NetworkException(
    String message, {
    this.url,
    this.statusCode,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Server-related exceptions
class ServerException extends PaymentException {
  final int statusCode;
  final Map<String, dynamic>? responseData;
  final bool isRetryable;

  ServerException(
    String message, {
    required this.statusCode,
    this.responseData,
    this.isRetryable = true,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Validation-related exceptions
class ValidationException extends PaymentException {
  final Map<String, String>? validationErrors;

  ValidationException(
    String message, {
    this.validationErrors,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Authentication exceptions
class AuthenticationException extends PaymentException {
  AuthenticationException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Payment method exceptions
class PaymentMethodException extends PaymentException {
  final String paymentMethod;
  final String? paymentMethodId;

  PaymentMethodException(
    String message, {
    required this.paymentMethod,
    this.paymentMethodId,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// 3D Secure exceptions
class ThreeDSecureException extends PaymentException {
  final String? transactionId;
  final String? acsUrl;
  final ThreeDSecureErrorType errorType;

  ThreeDSecureException(
    String message, {
    this.transactionId,
    this.acsUrl,
    required this.errorType,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// PCI compliance exceptions
class PCIComplianceException extends PaymentException {
  final List<PCIComplianceViolation> violations;

  PCIComplianceException(
    String message, {
    required this.violations,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Fraud detection exceptions
class FraudDetectionException extends PaymentException {
  final double riskScore;
  final List<String> riskFactors;
  final FraudAction requiredAction;

  FraudDetectionException(
    String message, {
    required this.riskScore,
    required this.riskFactors,
    required this.requiredAction,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Gateway exceptions
class GatewayException extends PaymentException {
  final String gateway;
  final String? gatewayTransactionId;
  final GatewayErrorType errorType;

  GatewayException(
    String message, {
    required this.gateway,
    this.gatewayTransactionId,
    required this.errorType,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Rate limiting exceptions
class RateLimitException extends PaymentException {
  final int retryAfterSeconds;
  final String? rateLimitType;

  RateLimitException(
    String message, {
    required this.retryAfterSeconds,
    this.rateLimitType,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Timeout exceptions
class TimeoutException extends PaymentException {
  final Duration timeout;
  final String? operation;

  TimeoutException(
    String message, {
    required this.timeout,
    this.operation,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Configuration exceptions
class ConfigurationException extends PaymentException {
  final String configurationKey;
  final String? expectedValue;

  ConfigurationException(
    String message, {
    required this.configurationKey,
    this.expectedValue,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Data access exceptions
class DataAccessException extends PaymentException {
  final String dataType;
  final String? operation;

  DataAccessException(
    String message, {
    required this.dataType,
    this.operation,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Helper methods for creating specific exceptions

class PaymentExceptionFactory {
  static PaymentException fromHttpResponse(
    int statusCode,
    String message, {
    Map<String, dynamic>? responseData,
    String? url,
  }) {
    switch (statusCode) {
      case 400:
        return ValidationException(
          message,
          validationErrors: _extractValidationErrors(responseData),
          code: 'VALIDATION_ERROR',
        );
      case 401:
      case 403:
        return AuthenticationException(
          message,
          code: 'AUTHENTICATION_ERROR',
        );
      case 402:
        return PaymentMethodException(
          message,
          paymentMethod: 'unknown',
          code: 'PAYMENT_DECLINED',
        );
      case 404:
        return DataAccessException(
          message,
          dataType: 'payment',
          operation: 'retrieve',
          code: 'NOT_FOUND',
        );
      case 429:
        final retryAfter = responseData?['retry_after'] as int? ?? 30;
        return RateLimitException(
          message,
          retryAfterSeconds: retryAfter,
          rateLimitType: responseData?['rate_limit_type'] as String?,
          code: 'RATE_LIMITED',
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message,
          statusCode: statusCode,
          responseData: responseData,
          isRetryable: statusCode == 503 || statusCode == 504,
          code: 'SERVER_ERROR',
        );
      default:
        return NetworkException(
          message,
          url: url,
          statusCode: statusCode,
          code: 'NETWORK_ERROR',
        );
    }
  }

  static Map<String, String>? _extractValidationErrors(Map<String, dynamic>? responseData) {
    if (responseData == null) return null;

    final errors = <String, String>{};
    if (responseData['errors'] is Map) {
      final errorsMap = responseData['errors'] as Map<String, dynamic>;
      errorsMap.forEach((key, value) {
        errors[key] = value.toString();
      });
    }
    return errors.isEmpty ? null : errors;
  }
}

// Enums for error types

enum ThreeDSecureErrorType {
  authenticationFailed,
  timeout,
  cancelled,
  technicalError,
  invalidData,
  challengeRequired,
}

enum GatewayErrorType {
  connectionError,
  authenticationError,
  processingError,
  timeout,
  declined,
  invalidRequest,
}

enum PCIComplianceViolation {
  tlsVersion,
  dataEncryption,
  accessControl,
  logging,
  vulnerability,
  configuration,
}

enum FraudAction {
  approve,
  decline,
  review,
  challenge,
}