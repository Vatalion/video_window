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

abstract class VerifyOtpRequest implements _i1.SerializableModel {
  VerifyOtpRequest._({
    required this.email,
    required this.code,
    required this.deviceId,
  });

  factory VerifyOtpRequest({
    required String email,
    required String code,
    required String deviceId,
  }) = _VerifyOtpRequestImpl;

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerifyOtpRequest(
      email: jsonSerialization['email'] as String,
      code: jsonSerialization['code'] as String,
      deviceId: jsonSerialization['deviceId'] as String,
    );
  }

  String email;

  String code;

  String deviceId;

  /// Returns a shallow copy of this [VerifyOtpRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  VerifyOtpRequest copyWith({
    String? email,
    String? code,
    String? deviceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
      'deviceId': deviceId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _VerifyOtpRequestImpl extends VerifyOtpRequest {
  _VerifyOtpRequestImpl({
    required String email,
    required String code,
    required String deviceId,
  }) : super._(
          email: email,
          code: code,
          deviceId: deviceId,
        );

  /// Returns a shallow copy of this [VerifyOtpRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  VerifyOtpRequest copyWith({
    String? email,
    String? code,
    String? deviceId,
  }) {
    return VerifyOtpRequest(
      email: email ?? this.email,
      code: code ?? this.code,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
