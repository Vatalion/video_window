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
import 'capabilities/capability_audit_event.dart' as _i12;
import 'capabilities/capability_request.dart' as _i13;
import 'capabilities/capability_request_dto.dart' as _i14;
import 'capabilities/capability_request_status.dart' as _i15;
import 'capabilities/capability_review_state.dart' as _i16;
import 'capabilities/capability_status_response.dart' as _i17;
import 'capabilities/capability_type.dart' as _i18;
import 'capabilities/trusted_device.dart' as _i19;
import 'capabilities/user_capabilities.dart' as _i20;
import 'capabilities/verification_task.dart' as _i21;
import 'capabilities/verification_task_status.dart' as _i22;
import 'capabilities/verification_task_type.dart' as _i23;
import 'feed/user_interaction.dart' as _i24;
import 'profile/dsar_request.dart' as _i25;
import 'profile/media_file.dart' as _i26;
import 'profile/notification_preferences.dart' as _i27;
import 'profile/privacy_audit_log.dart' as _i28;
import 'profile/privacy_settings.dart' as _i29;
import 'profile/user_profile.dart' as _i30;
import 'package:video_window_client/src/protocol/capabilities/capability_request.dart'
    as _i31;
import 'package:video_window_client/src/protocol/capabilities/trusted_device.dart'
    as _i32;
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
export 'capabilities/capability_audit_event.dart';
export 'capabilities/capability_request.dart';
export 'capabilities/capability_request_dto.dart';
export 'capabilities/capability_request_status.dart';
export 'capabilities/capability_review_state.dart';
export 'capabilities/capability_status_response.dart';
export 'capabilities/capability_type.dart';
export 'capabilities/trusted_device.dart';
export 'capabilities/user_capabilities.dart';
export 'capabilities/verification_task.dart';
export 'capabilities/verification_task_status.dart';
export 'capabilities/verification_task_type.dart';
export 'feed/user_interaction.dart';
export 'profile/dsar_request.dart';
export 'profile/media_file.dart';
export 'profile/notification_preferences.dart';
export 'profile/privacy_audit_log.dart';
export 'profile/privacy_settings.dart';
export 'profile/user_profile.dart';
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
    if (t == _i12.CapabilityAuditEvent) {
      return _i12.CapabilityAuditEvent.fromJson(data) as T;
    }
    if (t == _i13.CapabilityRequest) {
      return _i13.CapabilityRequest.fromJson(data) as T;
    }
    if (t == _i14.CapabilityRequestDto) {
      return _i14.CapabilityRequestDto.fromJson(data) as T;
    }
    if (t == _i15.CapabilityRequestStatus) {
      return _i15.CapabilityRequestStatus.fromJson(data) as T;
    }
    if (t == _i16.CapabilityReviewState) {
      return _i16.CapabilityReviewState.fromJson(data) as T;
    }
    if (t == _i17.CapabilityStatusResponse) {
      return _i17.CapabilityStatusResponse.fromJson(data) as T;
    }
    if (t == _i18.CapabilityType) {
      return _i18.CapabilityType.fromJson(data) as T;
    }
    if (t == _i19.TrustedDevice) {
      return _i19.TrustedDevice.fromJson(data) as T;
    }
    if (t == _i20.UserCapabilities) {
      return _i20.UserCapabilities.fromJson(data) as T;
    }
    if (t == _i21.VerificationTask) {
      return _i21.VerificationTask.fromJson(data) as T;
    }
    if (t == _i22.VerificationTaskStatus) {
      return _i22.VerificationTaskStatus.fromJson(data) as T;
    }
    if (t == _i23.VerificationTaskType) {
      return _i23.VerificationTaskType.fromJson(data) as T;
    }
    if (t == _i24.UserInteraction) {
      return _i24.UserInteraction.fromJson(data) as T;
    }
    if (t == _i25.DsarRequest) {
      return _i25.DsarRequest.fromJson(data) as T;
    }
    if (t == _i26.MediaFile) {
      return _i26.MediaFile.fromJson(data) as T;
    }
    if (t == _i27.NotificationPreferences) {
      return _i27.NotificationPreferences.fromJson(data) as T;
    }
    if (t == _i28.PrivacyAuditLog) {
      return _i28.PrivacyAuditLog.fromJson(data) as T;
    }
    if (t == _i29.PrivacySettings) {
      return _i29.PrivacySettings.fromJson(data) as T;
    }
    if (t == _i30.UserProfile) {
      return _i30.UserProfile.fromJson(data) as T;
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
    if (t == _i1.getType<_i12.CapabilityAuditEvent?>()) {
      return (data != null ? _i12.CapabilityAuditEvent.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.CapabilityRequest?>()) {
      return (data != null ? _i13.CapabilityRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.CapabilityRequestDto?>()) {
      return (data != null ? _i14.CapabilityRequestDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.CapabilityRequestStatus?>()) {
      return (data != null ? _i15.CapabilityRequestStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.CapabilityReviewState?>()) {
      return (data != null ? _i16.CapabilityReviewState.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.CapabilityStatusResponse?>()) {
      return (data != null
          ? _i17.CapabilityStatusResponse.fromJson(data)
          : null) as T;
    }
    if (t == _i1.getType<_i18.CapabilityType?>()) {
      return (data != null ? _i18.CapabilityType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.TrustedDevice?>()) {
      return (data != null ? _i19.TrustedDevice.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.UserCapabilities?>()) {
      return (data != null ? _i20.UserCapabilities.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.VerificationTask?>()) {
      return (data != null ? _i21.VerificationTask.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.VerificationTaskStatus?>()) {
      return (data != null ? _i22.VerificationTaskStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.VerificationTaskType?>()) {
      return (data != null ? _i23.VerificationTaskType.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i24.UserInteraction?>()) {
      return (data != null ? _i24.UserInteraction.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.DsarRequest?>()) {
      return (data != null ? _i25.DsarRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.MediaFile?>()) {
      return (data != null ? _i26.MediaFile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.NotificationPreferences?>()) {
      return (data != null ? _i27.NotificationPreferences.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.PrivacyAuditLog?>()) {
      return (data != null ? _i28.PrivacyAuditLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.PrivacySettings?>()) {
      return (data != null ? _i29.PrivacySettings.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.UserProfile?>()) {
      return (data != null ? _i30.UserProfile.fromJson(data) : null) as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map((k, v) =>
          MapEntry(deserialize<String>(k), deserialize<String>(v))) as T;
    }
    if (t == List<_i31.CapabilityRequest>) {
      return (data as List)
          .map((e) => deserialize<_i31.CapabilityRequest>(e))
          .toList() as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map((k, v) =>
          MapEntry(deserialize<String>(k), deserialize<dynamic>(v))) as T;
    }
    if (t == List<_i32.TrustedDevice>) {
      return (data as List)
          .map((e) => deserialize<_i32.TrustedDevice>(e))
          .toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
          ? (data as List).map((e) => deserialize<String>(e)).toList()
          : null) as T;
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
    if (data is _i12.CapabilityAuditEvent) {
      return 'CapabilityAuditEvent';
    }
    if (data is _i13.CapabilityRequest) {
      return 'CapabilityRequest';
    }
    if (data is _i14.CapabilityRequestDto) {
      return 'CapabilityRequestDto';
    }
    if (data is _i15.CapabilityRequestStatus) {
      return 'CapabilityRequestStatus';
    }
    if (data is _i16.CapabilityReviewState) {
      return 'CapabilityReviewState';
    }
    if (data is _i17.CapabilityStatusResponse) {
      return 'CapabilityStatusResponse';
    }
    if (data is _i18.CapabilityType) {
      return 'CapabilityType';
    }
    if (data is _i19.TrustedDevice) {
      return 'TrustedDevice';
    }
    if (data is _i20.UserCapabilities) {
      return 'UserCapabilities';
    }
    if (data is _i21.VerificationTask) {
      return 'VerificationTask';
    }
    if (data is _i22.VerificationTaskStatus) {
      return 'VerificationTaskStatus';
    }
    if (data is _i23.VerificationTaskType) {
      return 'VerificationTaskType';
    }
    if (data is _i24.UserInteraction) {
      return 'UserInteraction';
    }
    if (data is _i25.DsarRequest) {
      return 'DsarRequest';
    }
    if (data is _i26.MediaFile) {
      return 'MediaFile';
    }
    if (data is _i27.NotificationPreferences) {
      return 'NotificationPreferences';
    }
    if (data is _i28.PrivacyAuditLog) {
      return 'PrivacyAuditLog';
    }
    if (data is _i29.PrivacySettings) {
      return 'PrivacySettings';
    }
    if (data is _i30.UserProfile) {
      return 'UserProfile';
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
    if (dataClassName == 'CapabilityAuditEvent') {
      return deserialize<_i12.CapabilityAuditEvent>(data['data']);
    }
    if (dataClassName == 'CapabilityRequest') {
      return deserialize<_i13.CapabilityRequest>(data['data']);
    }
    if (dataClassName == 'CapabilityRequestDto') {
      return deserialize<_i14.CapabilityRequestDto>(data['data']);
    }
    if (dataClassName == 'CapabilityRequestStatus') {
      return deserialize<_i15.CapabilityRequestStatus>(data['data']);
    }
    if (dataClassName == 'CapabilityReviewState') {
      return deserialize<_i16.CapabilityReviewState>(data['data']);
    }
    if (dataClassName == 'CapabilityStatusResponse') {
      return deserialize<_i17.CapabilityStatusResponse>(data['data']);
    }
    if (dataClassName == 'CapabilityType') {
      return deserialize<_i18.CapabilityType>(data['data']);
    }
    if (dataClassName == 'TrustedDevice') {
      return deserialize<_i19.TrustedDevice>(data['data']);
    }
    if (dataClassName == 'UserCapabilities') {
      return deserialize<_i20.UserCapabilities>(data['data']);
    }
    if (dataClassName == 'VerificationTask') {
      return deserialize<_i21.VerificationTask>(data['data']);
    }
    if (dataClassName == 'VerificationTaskStatus') {
      return deserialize<_i22.VerificationTaskStatus>(data['data']);
    }
    if (dataClassName == 'VerificationTaskType') {
      return deserialize<_i23.VerificationTaskType>(data['data']);
    }
    if (dataClassName == 'UserInteraction') {
      return deserialize<_i24.UserInteraction>(data['data']);
    }
    if (dataClassName == 'DsarRequest') {
      return deserialize<_i25.DsarRequest>(data['data']);
    }
    if (dataClassName == 'MediaFile') {
      return deserialize<_i26.MediaFile>(data['data']);
    }
    if (dataClassName == 'NotificationPreferences') {
      return deserialize<_i27.NotificationPreferences>(data['data']);
    }
    if (dataClassName == 'PrivacyAuditLog') {
      return deserialize<_i28.PrivacyAuditLog>(data['data']);
    }
    if (dataClassName == 'PrivacySettings') {
      return deserialize<_i29.PrivacySettings>(data['data']);
    }
    if (dataClassName == 'UserProfile') {
      return deserialize<_i30.UserProfile>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
