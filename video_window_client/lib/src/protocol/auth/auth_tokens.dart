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

abstract class AuthTokens implements _i1.SerializableModel {
  AuthTokens._({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required String tokenType,
  }) = _AuthTokensImpl;

  factory AuthTokens.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthTokens(
      accessToken: jsonSerialization['accessToken'] as String,
      refreshToken: jsonSerialization['refreshToken'] as String,
      expiresIn: jsonSerialization['expiresIn'] as int,
      tokenType: jsonSerialization['tokenType'] as String,
    );
  }

  String accessToken;

  String refreshToken;

  int expiresIn;

  String tokenType;

  /// Returns a shallow copy of this [AuthTokens]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'tokenType': tokenType,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AuthTokensImpl extends AuthTokens {
  _AuthTokensImpl({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required String tokenType,
  }) : super._(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: expiresIn,
          tokenType: tokenType,
        );

  /// Returns a shallow copy of this [AuthTokens]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      tokenType: tokenType ?? this.tokenType,
    );
  }
}
