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

abstract class OtpResponse implements _i1.SerializableModel {
  OtpResponse._({
    required this.success,
    this.message,
    this.retryAfter,
  });

  factory OtpResponse({
    required bool success,
    String? message,
    int? retryAfter,
  }) = _OtpResponseImpl;

  factory OtpResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtpResponse(
      success: jsonSerialization['success'] as bool,
      message: jsonSerialization['message'] as String?,
      retryAfter: jsonSerialization['retryAfter'] as int?,
    );
  }

  bool success;

  String? message;

  int? retryAfter;

  /// Returns a shallow copy of this [OtpResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtpResponse copyWith({
    bool? success,
    String? message,
    int? retryAfter,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (retryAfter != null) 'retryAfter': retryAfter,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtpResponseImpl extends OtpResponse {
  _OtpResponseImpl({
    required bool success,
    String? message,
    int? retryAfter,
  }) : super._(
          success: success,
          message: message,
          retryAfter: retryAfter,
        );

  /// Returns a shallow copy of this [OtpResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtpResponse copyWith({
    bool? success,
    Object? message = _Undefined,
    Object? retryAfter = _Undefined,
  }) {
    return OtpResponse(
      success: success ?? this.success,
      message: message is String? ? message : this.message,
      retryAfter: retryAfter is int? ? retryAfter : this.retryAfter,
    );
  }
}
