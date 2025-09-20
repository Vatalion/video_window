import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {
  final String message;

  const ServerFailure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  final String message;

  const NetworkFailure(this.message);

  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;

  const CacheFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AuthenticationFailure extends Failure {
  final String message;

  const AuthenticationFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AuthorizationFailure extends Failure {
  final String message;

  const AuthorizationFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ValidationFailure extends Failure {
  final String message;
  final Map<String, String> errors;

  const ValidationFailure(this.message, [this.errors = const {}]);

  @override
  List<Object> get props => [message, errors];
}

class DeviceNotFoundFailure extends Failure {
  final String deviceId;

  const DeviceNotFoundFailure(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}

class DeviceAlreadyRegisteredFailure extends Failure {
  final String deviceId;

  const DeviceAlreadyRegisteredFailure(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}

class SuspiciousDeviceFailure extends Failure {
  final String deviceId;
  final String reason;

  const SuspiciousDeviceFailure(this.deviceId, this.reason);

  @override
  List<Object> get props => [deviceId, reason];
}

class DeviceSessionExpiredFailure extends Failure {
  final String sessionId;

  const DeviceSessionExpiredFailure(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}