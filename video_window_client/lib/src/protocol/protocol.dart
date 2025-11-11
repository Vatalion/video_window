/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'greeting.dart' as _i2;
import 'auth/auth_tokens.dart' as _i3;
import 'auth/otp.dart' as _i4;
import 'auth/otp_request.dart' as _i5;
import 'auth/otp_response.dart' as _i6;
import 'auth/recovery_token.dart' as _i7;
import 'auth/session.dart' as _i8;
import 'auth/token_blacklist.dart' as _i9;
import 'auth/user.dart' as _i10;
import 'auth/verify_otp_request.dart' as _i11;
export 'greeting.dart';
export 'auth/auth_tokens.dart';
export 'auth/otp.dart';
export 'auth/otp_request.dart';
export 'auth/otp_response.dart';
export 'auth/recovery_token.dart';
export 'auth/session.dart';
export 'auth/token_blacklist.dart';
export 'auth/user.dart';
export 'auth/verify_otp_request.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    if (t == _i2.Greeting) {
      return _i2.Greeting.fromJson(data) as T;
    }
    if (t == _i3.AuthTokens) {
      return _i3.AuthTokens.fromJson(data) as T;
    }
    if (t == _i4.Otp) {
      return _i4.Otp.fromJson(data) as T;
    }
    if (t == _i5.OtpRequest) {
      return _i5.OtpRequest.fromJson(data) as T;
    }
    if (t == _i6.OtpResponse) {
      return _i6.OtpResponse.fromJson(data) as T;
    }
    if (t == _i7.RecoveryToken) {
      return _i7.RecoveryToken.fromJson(data) as T;
    }
    if (t == _i8.UserSession) {
      return _i8.UserSession.fromJson(data) as T;
    }
    if (t == _i9.TokenBlacklist) {
      return _i9.TokenBlacklist.fromJson(data) as T;
    }
    if (t == _i10.User) {
      return _i10.User.fromJson(data) as T;
    }
    if (t == _i11.VerifyOtpRequest) {
      return _i11.VerifyOtpRequest.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Greeting?>()) {
      return (data != null ? _i2.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AuthTokens?>()) {
      return (data != null ? _i3.AuthTokens.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Otp?>()) {
      return (data != null ? _i4.Otp.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.OtpRequest?>()) {
      return (data != null ? _i5.OtpRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.OtpResponse?>()) {
      return (data != null ? _i6.OtpResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.RecoveryToken?>()) {
      return (data != null ? _i7.RecoveryToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.UserSession?>()) {
      return (data != null ? _i8.UserSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.TokenBlacklist?>()) {
      return (data != null ? _i9.TokenBlacklist.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.User?>()) {
      return (data != null ? _i10.User.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.VerifyOtpRequest?>()) {
      return (data != null ? _i11.VerifyOtpRequest.fromJson(data) : null) as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map((k, v) =>
          MapEntry(deserialize<String>(k), deserialize<dynamic>(v))) as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
          ? (data as Map).map((k, v) =>
              MapEntry(deserialize<String>(k), deserialize<dynamic>(v)))
          : null) as T;
    }
    if (t == List<Map<String, dynamic>>) {
      return (data as List)
          .map((e) => deserialize<Map<String, dynamic>>(e))
          .toList() as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i2.Greeting) {
      return 'Greeting';
    }
    if (data is _i3.AuthTokens) {
      return 'AuthTokens';
    }
    if (data is _i4.Otp) {
      return 'Otp';
    }
    if (data is _i5.OtpRequest) {
      return 'OtpRequest';
    }
    if (data is _i6.OtpResponse) {
      return 'OtpResponse';
    }
    if (data is _i7.RecoveryToken) {
      return 'RecoveryToken';
    }
    if (data is _i8.UserSession) {
      return 'UserSession';
    }
    if (data is _i9.TokenBlacklist) {
      return 'TokenBlacklist';
    }
    if (data is _i10.User) {
      return 'User';
    }
    if (data is _i11.VerifyOtpRequest) {
      return 'VerifyOtpRequest';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i2.Greeting>(data['data']);
    }
    if (dataClassName == 'AuthTokens') {
      return deserialize<_i3.AuthTokens>(data['data']);
    }
    if (dataClassName == 'Otp') {
      return deserialize<_i4.Otp>(data['data']);
    }
    if (dataClassName == 'OtpRequest') {
      return deserialize<_i5.OtpRequest>(data['data']);
    }
    if (dataClassName == 'OtpResponse') {
      return deserialize<_i6.OtpResponse>(data['data']);
    }
    if (dataClassName == 'RecoveryToken') {
      return deserialize<_i7.RecoveryToken>(data['data']);
    }
    if (dataClassName == 'UserSession') {
      return deserialize<_i8.UserSession>(data['data']);
    }
    if (dataClassName == 'TokenBlacklist') {
      return deserialize<_i9.TokenBlacklist>(data['data']);
    }
    if (dataClassName == 'User') {
      return deserialize<_i10.User>(data['data']);
    }
    if (dataClassName == 'VerifyOtpRequest') {
      return deserialize<_i11.VerifyOtpRequest>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
