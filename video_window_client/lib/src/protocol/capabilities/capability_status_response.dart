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
import '../capabilities/capability_review_state.dart' as _i2;

abstract class CapabilityStatusResponse implements _i1.SerializableModel {
  CapabilityStatusResponse._({
    required this.userId,
    required this.canPublish,
    required this.canCollectPayments,
    required this.canFulfillOrders,
    this.identityVerifiedAt,
    this.payoutConfiguredAt,
    this.fulfillmentEnabledAt,
    required this.reviewState,
    required this.blockers,
  });

  factory CapabilityStatusResponse({
    required int userId,
    required bool canPublish,
    required bool canCollectPayments,
    required bool canFulfillOrders,
    DateTime? identityVerifiedAt,
    DateTime? payoutConfiguredAt,
    DateTime? fulfillmentEnabledAt,
    required _i2.CapabilityReviewState reviewState,
    required Map<String, String> blockers,
  }) = _CapabilityStatusResponseImpl;

  factory CapabilityStatusResponse.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return CapabilityStatusResponse(
      userId: jsonSerialization['userId'] as int,
      canPublish: jsonSerialization['canPublish'] as bool,
      canCollectPayments: jsonSerialization['canCollectPayments'] as bool,
      canFulfillOrders: jsonSerialization['canFulfillOrders'] as bool,
      identityVerifiedAt: jsonSerialization['identityVerifiedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['identityVerifiedAt']),
      payoutConfiguredAt: jsonSerialization['payoutConfiguredAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['payoutConfiguredAt']),
      fulfillmentEnabledAt: jsonSerialization['fulfillmentEnabledAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['fulfillmentEnabledAt']),
      reviewState: _i2.CapabilityReviewState.fromJson(
          (jsonSerialization['reviewState'] as int)),
      blockers: (jsonSerialization['blockers'] as Map).map((k, v) => MapEntry(
            k as String,
            v as String,
          )),
    );
  }

  int userId;

  bool canPublish;

  bool canCollectPayments;

  bool canFulfillOrders;

  DateTime? identityVerifiedAt;

  DateTime? payoutConfiguredAt;

  DateTime? fulfillmentEnabledAt;

  _i2.CapabilityReviewState reviewState;

  Map<String, String> blockers;

  /// Returns a shallow copy of this [CapabilityStatusResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CapabilityStatusResponse copyWith({
    int? userId,
    bool? canPublish,
    bool? canCollectPayments,
    bool? canFulfillOrders,
    DateTime? identityVerifiedAt,
    DateTime? payoutConfiguredAt,
    DateTime? fulfillmentEnabledAt,
    _i2.CapabilityReviewState? reviewState,
    Map<String, String>? blockers,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'canPublish': canPublish,
      'canCollectPayments': canCollectPayments,
      'canFulfillOrders': canFulfillOrders,
      if (identityVerifiedAt != null)
        'identityVerifiedAt': identityVerifiedAt?.toJson(),
      if (payoutConfiguredAt != null)
        'payoutConfiguredAt': payoutConfiguredAt?.toJson(),
      if (fulfillmentEnabledAt != null)
        'fulfillmentEnabledAt': fulfillmentEnabledAt?.toJson(),
      'reviewState': reviewState.toJson(),
      'blockers': blockers.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CapabilityStatusResponseImpl extends CapabilityStatusResponse {
  _CapabilityStatusResponseImpl({
    required int userId,
    required bool canPublish,
    required bool canCollectPayments,
    required bool canFulfillOrders,
    DateTime? identityVerifiedAt,
    DateTime? payoutConfiguredAt,
    DateTime? fulfillmentEnabledAt,
    required _i2.CapabilityReviewState reviewState,
    required Map<String, String> blockers,
  }) : super._(
          userId: userId,
          canPublish: canPublish,
          canCollectPayments: canCollectPayments,
          canFulfillOrders: canFulfillOrders,
          identityVerifiedAt: identityVerifiedAt,
          payoutConfiguredAt: payoutConfiguredAt,
          fulfillmentEnabledAt: fulfillmentEnabledAt,
          reviewState: reviewState,
          blockers: blockers,
        );

  /// Returns a shallow copy of this [CapabilityStatusResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CapabilityStatusResponse copyWith({
    int? userId,
    bool? canPublish,
    bool? canCollectPayments,
    bool? canFulfillOrders,
    Object? identityVerifiedAt = _Undefined,
    Object? payoutConfiguredAt = _Undefined,
    Object? fulfillmentEnabledAt = _Undefined,
    _i2.CapabilityReviewState? reviewState,
    Map<String, String>? blockers,
  }) {
    return CapabilityStatusResponse(
      userId: userId ?? this.userId,
      canPublish: canPublish ?? this.canPublish,
      canCollectPayments: canCollectPayments ?? this.canCollectPayments,
      canFulfillOrders: canFulfillOrders ?? this.canFulfillOrders,
      identityVerifiedAt: identityVerifiedAt is DateTime?
          ? identityVerifiedAt
          : this.identityVerifiedAt,
      payoutConfiguredAt: payoutConfiguredAt is DateTime?
          ? payoutConfiguredAt
          : this.payoutConfiguredAt,
      fulfillmentEnabledAt: fulfillmentEnabledAt is DateTime?
          ? fulfillmentEnabledAt
          : this.fulfillmentEnabledAt,
      reviewState: reviewState ?? this.reviewState,
      blockers: blockers ??
          this.blockers.map((
                key0,
                value0,
              ) =>
                  MapEntry(
                    key0,
                    value0,
                  )),
    );
  }
}
