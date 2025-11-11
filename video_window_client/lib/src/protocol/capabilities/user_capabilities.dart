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

abstract class UserCapabilities implements _i1.SerializableModel {
  UserCapabilities._({
    this.id,
    required this.userId,
    required this.canPublish,
    required this.canCollectPayments,
    required this.canFulfillOrders,
    this.identityVerifiedAt,
    this.payoutConfiguredAt,
    this.fulfillmentEnabledAt,
    required this.reviewState,
    required this.blockers,
    required this.updatedAt,
    required this.createdAt,
  });

  factory UserCapabilities({
    int? id,
    required int userId,
    required bool canPublish,
    required bool canCollectPayments,
    required bool canFulfillOrders,
    DateTime? identityVerifiedAt,
    DateTime? payoutConfiguredAt,
    DateTime? fulfillmentEnabledAt,
    required _i2.CapabilityReviewState reviewState,
    required String blockers,
    required DateTime updatedAt,
    required DateTime createdAt,
  }) = _UserCapabilitiesImpl;

  factory UserCapabilities.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserCapabilities(
      id: jsonSerialization['id'] as int?,
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
      blockers: jsonSerialization['blockers'] as String,
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  bool canPublish;

  bool canCollectPayments;

  bool canFulfillOrders;

  DateTime? identityVerifiedAt;

  DateTime? payoutConfiguredAt;

  DateTime? fulfillmentEnabledAt;

  _i2.CapabilityReviewState reviewState;

  String blockers;

  DateTime updatedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [UserCapabilities]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserCapabilities copyWith({
    int? id,
    int? userId,
    bool? canPublish,
    bool? canCollectPayments,
    bool? canFulfillOrders,
    DateTime? identityVerifiedAt,
    DateTime? payoutConfiguredAt,
    DateTime? fulfillmentEnabledAt,
    _i2.CapabilityReviewState? reviewState,
    String? blockers,
    DateTime? updatedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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
      'blockers': blockers,
      'updatedAt': updatedAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserCapabilitiesImpl extends UserCapabilities {
  _UserCapabilitiesImpl({
    int? id,
    required int userId,
    required bool canPublish,
    required bool canCollectPayments,
    required bool canFulfillOrders,
    DateTime? identityVerifiedAt,
    DateTime? payoutConfiguredAt,
    DateTime? fulfillmentEnabledAt,
    required _i2.CapabilityReviewState reviewState,
    required String blockers,
    required DateTime updatedAt,
    required DateTime createdAt,
  }) : super._(
          id: id,
          userId: userId,
          canPublish: canPublish,
          canCollectPayments: canCollectPayments,
          canFulfillOrders: canFulfillOrders,
          identityVerifiedAt: identityVerifiedAt,
          payoutConfiguredAt: payoutConfiguredAt,
          fulfillmentEnabledAt: fulfillmentEnabledAt,
          reviewState: reviewState,
          blockers: blockers,
          updatedAt: updatedAt,
          createdAt: createdAt,
        );

  /// Returns a shallow copy of this [UserCapabilities]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserCapabilities copyWith({
    Object? id = _Undefined,
    int? userId,
    bool? canPublish,
    bool? canCollectPayments,
    bool? canFulfillOrders,
    Object? identityVerifiedAt = _Undefined,
    Object? payoutConfiguredAt = _Undefined,
    Object? fulfillmentEnabledAt = _Undefined,
    _i2.CapabilityReviewState? reviewState,
    String? blockers,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return UserCapabilities(
      id: id is int? ? id : this.id,
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
      blockers: blockers ?? this.blockers,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
