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
import 'dart:async' as _i2;
import 'package:video_window_client/src/protocol/capabilities/capability_status_response.dart'
    as _i3;
import 'package:video_window_client/src/protocol/capabilities/capability_request_dto.dart'
    as _i4;
import 'package:video_window_client/src/protocol/capabilities/capability_request.dart'
    as _i5;
import 'package:video_window_client/src/protocol/capabilities/verification_task.dart'
    as _i6;
import 'package:video_window_client/src/protocol/capabilities/trusted_device.dart'
    as _i7;
import 'package:video_window_client/src/protocol/profile/user_profile.dart'
    as _i8;
import 'package:video_window_client/src/protocol/profile/privacy_settings.dart'
    as _i9;
import 'package:video_window_client/src/protocol/profile/notification_preferences.dart'
    as _i10;
import 'package:video_window_client/src/protocol/greeting.dart' as _i11;
import 'protocol.dart' as _i12;

/// Capability endpoint for managing user capability requests and status
/// Implements Story 2-1: Capability Enablement Request Flow
/// {@category Endpoint}
class EndpointCapability extends _i1.EndpointRef {
  EndpointCapability(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'capability';

  /// Get current capability status for user
  /// Cached for ≤10 seconds per user
  ///
  /// AC1: Capability Center screen surfaces current capability status, blockers, and CTAs
  _i2.Future<_i3.CapabilityStatusResponse> getStatus(int userId) =>
      caller.callServerEndpoint<_i3.CapabilityStatusResponse>(
        'capability',
        'getStatus',
        {'userId': userId},
      );

  /// Request a capability (idempotent)
  /// Rate limited: 5 requests per minute per user
  ///
  /// AC2: Inline prompts detect missing capability and open guided checklist
  /// AC3: Submitting a request calls POST /capabilities/request, persists metadata, idempotent
  /// AC4: Audit event capability.requested is emitted
  /// AC5: Analytics event capability_request_submitted is recorded
  _i2.Future<_i3.CapabilityStatusResponse> requestCapability(
    int userId,
    _i4.CapabilityRequestDto request,
  ) =>
      caller.callServerEndpoint<_i3.CapabilityStatusResponse>(
        'capability',
        'requestCapability',
        {
          'userId': userId,
          'request': request,
        },
      );

  /// Get capability request history for user
  _i2.Future<List<_i5.CapabilityRequest>> getRequests(int userId) =>
      caller.callServerEndpoint<List<_i5.CapabilityRequest>>(
        'capability',
        'getRequests',
        {'userId': userId},
      );

  /// Complete a verification task (webhook endpoint)
  ///
  /// AC3: Persona webhook updates verification_task and toggles identityVerifiedAt when approved
  /// AC4: Validates webhook signature for security
  /// AC6: Emits audit event verification.completed with provider metadata, redacting PII
  ///
  /// POST /capabilities/tasks/{id}/complete
  _i2.Future<void> completeVerificationTask(
    int taskId,
    Map<String, dynamic> webhookPayload,
  ) =>
      caller.callServerEndpoint<void>(
        'capability',
        'completeVerificationTask',
        {
          'taskId': taskId,
          'webhookPayload': webhookPayload,
        },
      );

  /// Get verification task status
  ///
  /// GET /capabilities/tasks/{id}
  _i2.Future<_i6.VerificationTask?> getVerificationTask(int taskId) =>
      caller.callServerEndpoint<_i6.VerificationTask?>(
        'capability',
        'getVerificationTask',
        {'taskId': taskId},
      );

  /// Get Stripe onboarding link for payout activation
  ///
  /// AC1: Provides Stripe Express onboarding URL for payout setup
  /// POST /capabilities/stripe/onboarding-link
  _i2.Future<Map<String, dynamic>> getStripeOnboardingLink(
    int userId,
    String returnUrl,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'capability',
        'getStripeOnboardingLink',
        {
          'userId': userId,
          'returnUrl': returnUrl,
        },
      );
}

/// Device trust endpoint for managing device registration and trust
/// Implements Epic 2 Story 2-4: Device Trust & Risk Monitoring
/// {@category Endpoint}
class EndpointDevice extends _i1.EndpointRef {
  EndpointDevice(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'device';

  /// Register or update device telemetry
  /// AC1: Device registration occurs on app launch, capturing device ID, platform, attestation result, and telemetry
  ///
  /// POST /devices/register
  _i2.Future<_i7.TrustedDevice> registerDevice(
    int userId,
    String deviceId,
    String deviceType,
    String platform,
    Map<String, dynamic> telemetry,
  ) =>
      caller.callServerEndpoint<_i7.TrustedDevice>(
        'device',
        'registerDevice',
        {
          'userId': userId,
          'deviceId': deviceId,
          'deviceType': deviceType,
          'platform': platform,
          'telemetry': telemetry,
        },
      );

  /// Get all active devices for the current user
  /// AC3: Device management screen lists registered devices with trust score, last seen timestamp
  ///
  /// GET /devices
  _i2.Future<List<_i7.TrustedDevice>> getDevices(int userId) =>
      caller.callServerEndpoint<List<_i7.TrustedDevice>>(
        'device',
        'getDevices',
        {'userId': userId},
      );

  /// Revoke device trust
  /// AC3: Revocation lowers capability state appropriately
  ///
  /// POST /devices/{id}/revoke
  _i2.Future<void> revokeDevice(
    int userId,
    int deviceId,
    String? reason,
  ) =>
      caller.callServerEndpoint<void>(
        'device',
        'revokeDevice',
        {
          'userId': userId,
          'deviceId': deviceId,
          'reason': reason,
        },
      );
}

/// Health check endpoint for monitoring and smoke tests
/// {@category Endpoint}
class EndpointHealth extends _i1.EndpointRef {
  EndpointHealth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'health';

  /// Returns health status of the server
  _i2.Future<Map<String, dynamic>> check() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'health',
        'check',
        {},
      );
}

/// Authentication endpoint for user identity management
/// Implements Epic 1 - Viewer Authentication with full security controls
/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Send OTP for email authentication
  /// Rate limited: 3 requests/5min per email
  _i2.Future<Map<String, dynamic>> sendOtp(String email) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'sendOtp',
        {'email': email},
      );

  /// Verify OTP and create authenticated session
  /// Account lockout after failed attempts: 3→5min, 5→30min, 10→1hr, 15→24hr
  _i2.Future<Map<String, dynamic>> verifyOtp(
    String email,
    String code, {
    String? deviceId,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'verifyOtp',
        {
          'email': email,
          'code': code,
          'deviceId': deviceId,
        },
      );

  /// Refresh access token using refresh token
  /// Implements token rotation with reuse detection
  _i2.Future<Map<String, dynamic>> refresh(String refreshToken) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'refresh',
        {'refreshToken': refreshToken},
      );

  /// Logout and blacklist tokens
  _i2.Future<Map<String, dynamic>> logout(
    String accessToken,
    String refreshToken,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'logout',
        {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        },
      );

  /// Verify Apple Sign-In token and create/link account
  /// Implements account reconciliation to prevent duplicates
  _i2.Future<Map<String, dynamic>> verifyAppleToken(
    String idToken, {
    String? deviceId,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'verifyAppleToken',
        {
          'idToken': idToken,
          'deviceId': deviceId,
        },
      );

  /// Verify Google Sign-In token and create/link account
  /// Implements account reconciliation to prevent duplicates
  _i2.Future<Map<String, dynamic>> verifyGoogleToken(
    String idToken, {
    String? deviceId,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'verifyGoogleToken',
        {
          'idToken': idToken,
          'deviceId': deviceId,
        },
      );

  /// Send account recovery email
  /// AC1: Issues one-time recovery token with 15-minute expiry
  /// AC2: Email includes device + location metadata
  _i2.Future<Map<String, dynamic>> sendRecovery(
    String email, {
    String? deviceInfo,
    String? userAgent,
    String? location,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'sendRecovery',
        {
          'email': email,
          'deviceInfo': deviceInfo,
          'userAgent': userAgent,
          'location': location,
        },
      );

  /// Verify recovery token and create authenticated session
  /// AC3: Allows re-authentication and forces session rotation
  /// AC4: Brute force protection (3 attempts = 30 min lockout)
  /// AC5: Invalidates all active sessions on success
  _i2.Future<Map<String, dynamic>> verifyRecovery(
    String email,
    String token, {
    String? deviceId,
  }) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'verifyRecovery',
        {
          'email': email,
          'token': token,
          'deviceId': deviceId,
        },
      );

  /// Revoke recovery token immediately
  /// AC2: "Not You?" link revokes token and alerts user
  _i2.Future<Map<String, dynamic>> revokeRecovery(
    String email,
    String token,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'revokeRecovery',
        {
          'email': email,
          'token': token,
        },
      );
}

/// Endpoint for exposing Prometheus metrics
///
/// Provides /metrics endpoint that returns Prometheus-formatted metrics
/// for scraping by Prometheus server.
/// {@category Endpoint}
class EndpointMetrics extends _i1.EndpointRef {
  EndpointMetrics(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'metrics';

  /// Export metrics in Prometheus text format
  ///
  /// GET /metrics
  /// Returns: text/plain with Prometheus metrics
  _i2.Future<String> getMetrics() => caller.callServerEndpoint<String>(
        'metrics',
        'getMetrics',
        {},
      );

  /// Health check endpoint
  ///
  /// GET /metrics/health
  /// Returns: JSON with status
  _i2.Future<Map<String, dynamic>> getHealth() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'metrics',
        'getHealth',
        {},
      );
}

/// Offer submission endpoint for marketplace
/// Placeholder for Epic 9 - Offer Submission
/// {@category Endpoint}
class EndpointOffer extends _i1.EndpointRef {
  EndpointOffer(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'offer';

  /// Placeholder: Submit offer on story
  _i2.Future<Map<String, dynamic>> submitOffer(
    int storyId,
    double amount,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'offer',
        'submitOffer',
        {
          'storyId': storyId,
          'amount': amount,
        },
      );
}

/// Order management endpoint
/// Placeholder for Epic 13 - Shipping & Tracking
/// {@category Endpoint}
class EndpointOrder extends _i1.EndpointRef {
  EndpointOrder(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'order';

  /// Placeholder: Get order details
  _i2.Future<Map<String, dynamic>?> getOrder(int orderId) =>
      caller.callServerEndpoint<Map<String, dynamic>?>(
        'order',
        'getOrder',
        {'orderId': orderId},
      );

  /// Placeholder: Update shipping info
  _i2.Future<Map<String, dynamic>> updateShipping(
    int orderId,
    String trackingNumber,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'order',
        'updateShipping',
        {
          'orderId': orderId,
          'trackingNumber': trackingNumber,
        },
      );
}

/// Payment processing endpoint via Stripe
/// Implements Epic 12 - Checkout & Payment
/// Story 2-3: Guards checkout with canCollectPayments check
/// {@category Endpoint}
class EndpointPayment extends _i1.EndpointRef {
  EndpointPayment(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'payment';

  /// Create Stripe checkout session
  ///
  /// AC5: Guards checkout creation with canCollectPayments verification
  /// Returns error with blocker summary if capability not active
  _i2.Future<Map<String, dynamic>> createCheckoutSession(
    int userId,
    int orderId,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'payment',
        'createCheckoutSession',
        {
          'userId': userId,
          'orderId': orderId,
        },
      );
}

/// Media endpoint for avatar upload and virus scan callbacks
/// Implements Story 3-2: Avatar & Media Upload System
/// AC1: Presigned upload flow with chunked transfer, max 5 MB enforcement
/// AC2: Virus scanning pipeline dispatches uploads to AWS Lambda
/// AC5: All uploads require authenticated requests, signed URLs expire after 5 minutes
/// {@category Endpoint}
class EndpointMedia extends _i1.EndpointRef {
  EndpointMedia(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'media';

  /// Create presigned upload URL for avatar
  /// POST /media/avatar/upload-url
  /// AC1: Presigned upload flow with max 5 MB enforcement and MIME validation
  /// AC5: Authenticated requests required, signed URLs expire after 5 minutes
  _i2.Future<Map<String, dynamic>> createAvatarUploadUrl(
    int userId,
    String fileName,
    String mimeType,
    int fileSizeBytes,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'media',
        'createAvatarUploadUrl',
        {
          'userId': userId,
          'fileName': fileName,
          'mimeType': mimeType,
          'fileSizeBytes': fileSizeBytes,
        },
      );

  /// Handle virus scan callback from AWS Lambda
  /// POST /media/virus-scan-callback
  /// AC2: Virus scanning pipeline callback - updates media status
  _i2.Future<void> handleVirusScanCallback(Map<String, dynamic> callbackData) =>
      caller.callServerEndpoint<void>(
        'media',
        'handleVirusScanCallback',
        {'callbackData': callbackData},
      );
}

/// Profile endpoint for managing user profiles, privacy settings, and notifications
/// Implements Story 3-1: Viewer Profile Management
/// {@category Endpoint}
class EndpointProfile extends _i1.EndpointRef {
  EndpointProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'profile';

  /// Get current user profile
  /// GET /profile/me
  /// AC1: Complete profile management interface
  /// AC6: Role-based access control - users can only access their own profile
  _i2.Future<_i8.UserProfile?> getMyProfile(int userId) =>
      caller.callServerEndpoint<_i8.UserProfile?>(
        'profile',
        'getMyProfile',
        {'userId': userId},
      );

  /// Update current user profile
  /// PUT /profile/me
  /// AC1: Complete profile management interface with validation
  /// AC4: Sensitive PII data encrypted at rest
  /// AC6: Role-based access control enforced
  _i2.Future<_i8.UserProfile> updateMyProfile(
    int userId,
    Map<String, dynamic> profileData,
  ) =>
      caller.callServerEndpoint<_i8.UserProfile>(
        'profile',
        'updateMyProfile',
        {
          'userId': userId,
          'profileData': profileData,
        },
      );

  /// Get privacy settings
  /// GET /profile/privacy
  /// AC3: Granular privacy settings
  _i2.Future<_i9.PrivacySettings> getPrivacySettings(int userId) =>
      caller.callServerEndpoint<_i9.PrivacySettings>(
        'profile',
        'getPrivacySettings',
        {'userId': userId},
      );

  /// Update privacy settings
  /// PUT /profile/privacy
  /// AC3: Granular privacy settings with GDPR/CCPA compliance
  _i2.Future<_i9.PrivacySettings> updatePrivacySettings(
    int userId,
    Map<String, dynamic> settingsData,
  ) =>
      caller.callServerEndpoint<_i9.PrivacySettings>(
        'profile',
        'updatePrivacySettings',
        {
          'userId': userId,
          'settingsData': settingsData,
        },
      );

  /// Get notification preferences
  /// GET /profile/notifications
  /// AC7: Notification preference matrix
  _i2.Future<_i10.NotificationPreferences> getNotificationPreferences(
          int userId) =>
      caller.callServerEndpoint<_i10.NotificationPreferences>(
        'profile',
        'getNotificationPreferences',
        {'userId': userId},
      );

  /// Update notification preferences
  /// PUT /profile/notifications
  /// AC7: Notification preference matrix with granular controls
  _i2.Future<_i10.NotificationPreferences> updateNotificationPreferences(
    int userId,
    Map<String, dynamic> prefsData,
  ) =>
      caller.callServerEndpoint<_i10.NotificationPreferences>(
        'profile',
        'updateNotificationPreferences',
        {
          'userId': userId,
          'prefsData': prefsData,
        },
      );

  /// Export user data (DSAR - Right to Access)
  /// GET /profile/dsar/export
  /// AC5: DSAR functionality - data export
  _i2.Future<Map<String, dynamic>> exportUserData(int userId) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'profile',
        'exportUserData',
        {'userId': userId},
      );

  /// Delete user data (DSAR - Right to Erasure)
  /// DELETE /profile/dsar/delete
  /// AC5: DSAR functionality - data deletion with audit logging
  _i2.Future<void> deleteUserData(int userId) =>
      caller.callServerEndpoint<void>(
        'profile',
        'deleteUserData',
        {'userId': userId},
      );
}

/// Story content endpoint for video marketplace
/// Placeholder for Epic 4-8 - Feed, Playback, Publishing
/// {@category Endpoint}
class EndpointStory extends _i1.EndpointRef {
  EndpointStory(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'story';

  /// Placeholder: Get feed stories
  _i2.Future<List<Map<String, dynamic>>> getFeed({
    required int limit,
    required int offset,
  }) =>
      caller.callServerEndpoint<List<Map<String, dynamic>>>(
        'story',
        'getFeed',
        {
          'limit': limit,
          'offset': offset,
        },
      );

  /// Placeholder: Get story details
  _i2.Future<Map<String, dynamic>?> getStory(int storyId) =>
      caller.callServerEndpoint<Map<String, dynamic>?>(
        'story',
        'getStory',
        {'storyId': storyId},
      );
}

/// Stripe webhook endpoint for handling payout onboarding events
/// Implements Story 2-3: Payout & Compliance Activation
/// {@category Endpoint}
class EndpointStripeWebhook extends _i1.EndpointRef {
  EndpointStripeWebhook(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'stripeWebhook';

  /// Handle Stripe webhook events
  ///
  /// AC2: Processes Stripe Express onboarding webhooks
  /// AC4: Updates verification tasks and capability status
  _i2.Future<Map<String, dynamic>> handleWebhook(
    String payload,
    String signature,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'stripeWebhook',
        'handleWebhook',
        {
          'payload': payload,
          'signature': signature,
        },
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i11.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i11.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i12.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    capability = EndpointCapability(this);
    device = EndpointDevice(this);
    health = EndpointHealth(this);
    auth = EndpointAuth(this);
    metrics = EndpointMetrics(this);
    offer = EndpointOffer(this);
    order = EndpointOrder(this);
    payment = EndpointPayment(this);
    media = EndpointMedia(this);
    profile = EndpointProfile(this);
    story = EndpointStory(this);
    stripeWebhook = EndpointStripeWebhook(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointCapability capability;

  late final EndpointDevice device;

  late final EndpointHealth health;

  late final EndpointAuth auth;

  late final EndpointMetrics metrics;

  late final EndpointOffer offer;

  late final EndpointOrder order;

  late final EndpointPayment payment;

  late final EndpointMedia media;

  late final EndpointProfile profile;

  late final EndpointStory story;

  late final EndpointStripeWebhook stripeWebhook;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'capability': capability,
        'device': device,
        'health': health,
        'auth': auth,
        'metrics': metrics,
        'offer': offer,
        'order': order,
        'payment': payment,
        'media': media,
        'profile': profile,
        'story': story,
        'stripeWebhook': stripeWebhook,
        'greeting': greeting,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
