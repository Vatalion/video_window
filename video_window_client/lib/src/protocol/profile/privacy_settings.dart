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

abstract class PrivacySettings implements _i1.SerializableModel {
  PrivacySettings._({
    this.id,
    required this.userId,
    required this.profileVisibility,
    required this.showEmailToPublic,
    required this.showPhoneToFriends,
    required this.allowTagging,
    required this.allowSearchByPhone,
    required this.allowDataAnalytics,
    required this.allowMarketingEmails,
    required this.allowPushNotifications,
    required this.shareProfileWithPartners,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrivacySettings({
    int? id,
    required int userId,
    required String profileVisibility,
    required bool showEmailToPublic,
    required bool showPhoneToFriends,
    required bool allowTagging,
    required bool allowSearchByPhone,
    required bool allowDataAnalytics,
    required bool allowMarketingEmails,
    required bool allowPushNotifications,
    required bool shareProfileWithPartners,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PrivacySettingsImpl;

  factory PrivacySettings.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrivacySettings(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      profileVisibility: jsonSerialization['profileVisibility'] as String,
      showEmailToPublic: jsonSerialization['showEmailToPublic'] as bool,
      showPhoneToFriends: jsonSerialization['showPhoneToFriends'] as bool,
      allowTagging: jsonSerialization['allowTagging'] as bool,
      allowSearchByPhone: jsonSerialization['allowSearchByPhone'] as bool,
      allowDataAnalytics: jsonSerialization['allowDataAnalytics'] as bool,
      allowMarketingEmails: jsonSerialization['allowMarketingEmails'] as bool,
      allowPushNotifications:
          jsonSerialization['allowPushNotifications'] as bool,
      shareProfileWithPartners:
          jsonSerialization['shareProfileWithPartners'] as bool,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String profileVisibility;

  bool showEmailToPublic;

  bool showPhoneToFriends;

  bool allowTagging;

  bool allowSearchByPhone;

  bool allowDataAnalytics;

  bool allowMarketingEmails;

  bool allowPushNotifications;

  bool shareProfileWithPartners;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [PrivacySettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrivacySettings copyWith({
    int? id,
    int? userId,
    String? profileVisibility,
    bool? showEmailToPublic,
    bool? showPhoneToFriends,
    bool? allowTagging,
    bool? allowSearchByPhone,
    bool? allowDataAnalytics,
    bool? allowMarketingEmails,
    bool? allowPushNotifications,
    bool? shareProfileWithPartners,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'profileVisibility': profileVisibility,
      'showEmailToPublic': showEmailToPublic,
      'showPhoneToFriends': showPhoneToFriends,
      'allowTagging': allowTagging,
      'allowSearchByPhone': allowSearchByPhone,
      'allowDataAnalytics': allowDataAnalytics,
      'allowMarketingEmails': allowMarketingEmails,
      'allowPushNotifications': allowPushNotifications,
      'shareProfileWithPartners': shareProfileWithPartners,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrivacySettingsImpl extends PrivacySettings {
  _PrivacySettingsImpl({
    int? id,
    required int userId,
    required String profileVisibility,
    required bool showEmailToPublic,
    required bool showPhoneToFriends,
    required bool allowTagging,
    required bool allowSearchByPhone,
    required bool allowDataAnalytics,
    required bool allowMarketingEmails,
    required bool allowPushNotifications,
    required bool shareProfileWithPartners,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
          id: id,
          userId: userId,
          profileVisibility: profileVisibility,
          showEmailToPublic: showEmailToPublic,
          showPhoneToFriends: showPhoneToFriends,
          allowTagging: allowTagging,
          allowSearchByPhone: allowSearchByPhone,
          allowDataAnalytics: allowDataAnalytics,
          allowMarketingEmails: allowMarketingEmails,
          allowPushNotifications: allowPushNotifications,
          shareProfileWithPartners: shareProfileWithPartners,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [PrivacySettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrivacySettings copyWith({
    Object? id = _Undefined,
    int? userId,
    String? profileVisibility,
    bool? showEmailToPublic,
    bool? showPhoneToFriends,
    bool? allowTagging,
    bool? allowSearchByPhone,
    bool? allowDataAnalytics,
    bool? allowMarketingEmails,
    bool? allowPushNotifications,
    bool? shareProfileWithPartners,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrivacySettings(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showEmailToPublic: showEmailToPublic ?? this.showEmailToPublic,
      showPhoneToFriends: showPhoneToFriends ?? this.showPhoneToFriends,
      allowTagging: allowTagging ?? this.allowTagging,
      allowSearchByPhone: allowSearchByPhone ?? this.allowSearchByPhone,
      allowDataAnalytics: allowDataAnalytics ?? this.allowDataAnalytics,
      allowMarketingEmails: allowMarketingEmails ?? this.allowMarketingEmails,
      allowPushNotifications:
          allowPushNotifications ?? this.allowPushNotifications,
      shareProfileWithPartners:
          shareProfileWithPartners ?? this.shareProfileWithPartners,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
