/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/capabilities/capability_endpoint.dart' as _i2;
import '../endpoints/devices/device_endpoint.dart' as _i3;
import '../endpoints/health_endpoint.dart' as _i4;
import '../endpoints/identity/auth_endpoint.dart' as _i5;
import '../endpoints/metrics_endpoint.dart' as _i6;
import '../endpoints/offers/offer_endpoint.dart' as _i7;
import '../endpoints/orders/order_endpoint.dart' as _i8;
import '../endpoints/payments/payment_endpoint.dart' as _i9;
import '../endpoints/profile/profile_endpoint.dart' as _i10;
import '../endpoints/story/story_endpoint.dart' as _i11;
import '../endpoints/webhooks/stripe_webhook_endpoint.dart' as _i12;
import '../greeting_endpoint.dart' as _i13;
import 'package:video_window_server/src/generated/capabilities/capability_request_dto.dart'
    as _i14;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'capability': _i2.CapabilityEndpoint()
        ..initialize(
          server,
          'capability',
          null,
        ),
      'device': _i3.DeviceEndpoint()
        ..initialize(
          server,
          'device',
          null,
        ),
      'health': _i4.HealthEndpoint()
        ..initialize(
          server,
          'health',
          null,
        ),
      'auth': _i5.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'metrics': _i6.MetricsEndpoint()
        ..initialize(
          server,
          'metrics',
          null,
        ),
      'offer': _i7.OfferEndpoint()
        ..initialize(
          server,
          'offer',
          null,
        ),
      'order': _i8.OrderEndpoint()
        ..initialize(
          server,
          'order',
          null,
        ),
      'payment': _i9.PaymentEndpoint()
        ..initialize(
          server,
          'payment',
          null,
        ),
      'profile': _i10.ProfileEndpoint()
        ..initialize(
          server,
          'profile',
          null,
        ),
      'story': _i11.StoryEndpoint()
        ..initialize(
          server,
          'story',
          null,
        ),
      'stripeWebhook': _i12.StripeWebhookEndpoint()
        ..initialize(
          server,
          'stripeWebhook',
          null,
        ),
      'greeting': _i13.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['capability'] = _i1.EndpointConnector(
      name: 'capability',
      endpoint: endpoints['capability']!,
      methodConnectors: {
        'getStatus': _i1.MethodConnector(
          name: 'getStatus',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['capability'] as _i2.CapabilityEndpoint).getStatus(
            session,
            params['userId'],
          ),
        ),
        'requestCapability': _i1.MethodConnector(
          name: 'requestCapability',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i14.CapabilityRequestDto>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['capability'] as _i2.CapabilityEndpoint)
                  .requestCapability(
            session,
            params['userId'],
            params['request'],
          ),
        ),
        'getRequests': _i1.MethodConnector(
          name: 'getRequests',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['capability'] as _i2.CapabilityEndpoint).getRequests(
            session,
            params['userId'],
          ),
        ),
        'completeVerificationTask': _i1.MethodConnector(
          name: 'completeVerificationTask',
          params: {
            'taskId': _i1.ParameterDescription(
              name: 'taskId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'webhookPayload': _i1.ParameterDescription(
              name: 'webhookPayload',
              type: _i1.getType<Map<String, dynamic>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['capability'] as _i2.CapabilityEndpoint)
                  .completeVerificationTask(
            session,
            params['taskId'],
            params['webhookPayload'],
          ),
        ),
        'getVerificationTask': _i1.MethodConnector(
          name: 'getVerificationTask',
          params: {
            'taskId': _i1.ParameterDescription(
              name: 'taskId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['capability'] as _i2.CapabilityEndpoint)
                  .getVerificationTask(
            session,
            params['taskId'],
          ),
        ),
        'getStripeOnboardingLink': _i1.MethodConnector(
          name: 'getStripeOnboardingLink',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'returnUrl': _i1.ParameterDescription(
              name: 'returnUrl',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['capability'] as _i2.CapabilityEndpoint)
                  .getStripeOnboardingLink(
            session,
            params['userId'],
            params['returnUrl'],
          ),
        ),
      },
    );
    connectors['device'] = _i1.EndpointConnector(
      name: 'device',
      endpoint: endpoints['device']!,
      methodConnectors: {
        'registerDevice': _i1.MethodConnector(
          name: 'registerDevice',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'deviceId': _i1.ParameterDescription(
              name: 'deviceId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deviceType': _i1.ParameterDescription(
              name: 'deviceType',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'platform': _i1.ParameterDescription(
              name: 'platform',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'telemetry': _i1.ParameterDescription(
              name: 'telemetry',
              type: _i1.getType<Map<String, dynamic>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['device'] as _i3.DeviceEndpoint).registerDevice(
            session,
            params['userId'],
            params['deviceId'],
            params['deviceType'],
            params['platform'],
            params['telemetry'],
          ),
        ),
        'getDevices': _i1.MethodConnector(
          name: 'getDevices',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['device'] as _i3.DeviceEndpoint).getDevices(
            session,
            params['userId'],
          ),
        ),
        'revokeDevice': _i1.MethodConnector(
          name: 'revokeDevice',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'deviceId': _i1.ParameterDescription(
              name: 'deviceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'reason': _i1.ParameterDescription(
              name: 'reason',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['device'] as _i3.DeviceEndpoint).revokeDevice(
            session,
            params['userId'],
            params['deviceId'],
            params['reason'],
          ),
        ),
      },
    );
    connectors['health'] = _i1.EndpointConnector(
      name: 'health',
      endpoint: endpoints['health']!,
      methodConnectors: {
        'check': _i1.MethodConnector(
          name: 'check',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['health'] as _i4.HealthEndpoint).check(session),
        )
      },
    );
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'sendOtp': _i1.MethodConnector(
          name: 'sendOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).sendOtp(
            session,
            params['email'],
          ),
        ),
        'verifyOtp': _i1.MethodConnector(
          name: 'verifyOtp',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'code': _i1.ParameterDescription(
              name: 'code',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deviceId': _i1.ParameterDescription(
              name: 'deviceId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).verifyOtp(
            session,
            params['email'],
            params['code'],
            deviceId: params['deviceId'],
          ),
        ),
        'refresh': _i1.MethodConnector(
          name: 'refresh',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).refresh(
            session,
            params['refreshToken'],
          ),
        ),
        'logout': _i1.MethodConnector(
          name: 'logout',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).logout(
            session,
            params['accessToken'],
            params['refreshToken'],
          ),
        ),
        'verifyAppleToken': _i1.MethodConnector(
          name: 'verifyAppleToken',
          params: {
            'idToken': _i1.ParameterDescription(
              name: 'idToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deviceId': _i1.ParameterDescription(
              name: 'deviceId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).verifyAppleToken(
            session,
            params['idToken'],
            deviceId: params['deviceId'],
          ),
        ),
        'verifyGoogleToken': _i1.MethodConnector(
          name: 'verifyGoogleToken',
          params: {
            'idToken': _i1.ParameterDescription(
              name: 'idToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deviceId': _i1.ParameterDescription(
              name: 'deviceId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).verifyGoogleToken(
            session,
            params['idToken'],
            deviceId: params['deviceId'],
          ),
        ),
        'sendRecovery': _i1.MethodConnector(
          name: 'sendRecovery',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deviceInfo': _i1.ParameterDescription(
              name: 'deviceInfo',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'userAgent': _i1.ParameterDescription(
              name: 'userAgent',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'location': _i1.ParameterDescription(
              name: 'location',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).sendRecovery(
            session,
            params['email'],
            deviceInfo: params['deviceInfo'],
            userAgent: params['userAgent'],
            location: params['location'],
          ),
        ),
        'verifyRecovery': _i1.MethodConnector(
          name: 'verifyRecovery',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'deviceId': _i1.ParameterDescription(
              name: 'deviceId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).verifyRecovery(
            session,
            params['email'],
            params['token'],
            deviceId: params['deviceId'],
          ),
        ),
        'revokeRecovery': _i1.MethodConnector(
          name: 'revokeRecovery',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['auth'] as _i5.AuthEndpoint).revokeRecovery(
            session,
            params['email'],
            params['token'],
          ),
        ),
      },
    );
    connectors['metrics'] = _i1.EndpointConnector(
      name: 'metrics',
      endpoint: endpoints['metrics']!,
      methodConnectors: {
        'getMetrics': _i1.MethodConnector(
          name: 'getMetrics',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['metrics'] as _i6.MetricsEndpoint).getMetrics(session),
        ),
        'getHealth': _i1.MethodConnector(
          name: 'getHealth',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['metrics'] as _i6.MetricsEndpoint).getHealth(session),
        ),
      },
    );
    connectors['offer'] = _i1.EndpointConnector(
      name: 'offer',
      endpoint: endpoints['offer']!,
      methodConnectors: {
        'submitOffer': _i1.MethodConnector(
          name: 'submitOffer',
          params: {
            'storyId': _i1.ParameterDescription(
              name: 'storyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'amount': _i1.ParameterDescription(
              name: 'amount',
              type: _i1.getType<double>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['offer'] as _i7.OfferEndpoint).submitOffer(
            session,
            params['storyId'],
            params['amount'],
          ),
        )
      },
    );
    connectors['order'] = _i1.EndpointConnector(
      name: 'order',
      endpoint: endpoints['order']!,
      methodConnectors: {
        'getOrder': _i1.MethodConnector(
          name: 'getOrder',
          params: {
            'orderId': _i1.ParameterDescription(
              name: 'orderId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['order'] as _i8.OrderEndpoint).getOrder(
            session,
            params['orderId'],
          ),
        ),
        'updateShipping': _i1.MethodConnector(
          name: 'updateShipping',
          params: {
            'orderId': _i1.ParameterDescription(
              name: 'orderId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'trackingNumber': _i1.ParameterDescription(
              name: 'trackingNumber',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['order'] as _i8.OrderEndpoint).updateShipping(
            session,
            params['orderId'],
            params['trackingNumber'],
          ),
        ),
      },
    );
    connectors['payment'] = _i1.EndpointConnector(
      name: 'payment',
      endpoint: endpoints['payment']!,
      methodConnectors: {
        'createCheckoutSession': _i1.MethodConnector(
          name: 'createCheckoutSession',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'orderId': _i1.ParameterDescription(
              name: 'orderId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['payment'] as _i9.PaymentEndpoint)
                  .createCheckoutSession(
            session,
            params['userId'],
            params['orderId'],
          ),
        )
      },
    );
    connectors['profile'] = _i1.EndpointConnector(
      name: 'profile',
      endpoint: endpoints['profile']!,
      methodConnectors: {
        'getMyProfile': _i1.MethodConnector(
          name: 'getMyProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['profile'] as _i10.ProfileEndpoint).getMyProfile(
            session,
            params['userId'],
          ),
        ),
        'updateMyProfile': _i1.MethodConnector(
          name: 'updateMyProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'profileData': _i1.ParameterDescription(
              name: 'profileData',
              type: _i1.getType<Map<String, dynamic>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['profile'] as _i10.ProfileEndpoint).updateMyProfile(
            session,
            params['userId'],
            params['profileData'],
          ),
        ),
        'getPrivacySettings': _i1.MethodConnector(
          name: 'getPrivacySettings',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['profile'] as _i10.ProfileEndpoint).getPrivacySettings(
            session,
            params['userId'],
          ),
        ),
        'updatePrivacySettings': _i1.MethodConnector(
          name: 'updatePrivacySettings',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'settingsData': _i1.ParameterDescription(
              name: 'settingsData',
              type: _i1.getType<Map<String, dynamic>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['profile'] as _i10.ProfileEndpoint)
                  .updatePrivacySettings(
            session,
            params['userId'],
            params['settingsData'],
          ),
        ),
        'getNotificationPreferences': _i1.MethodConnector(
          name: 'getNotificationPreferences',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['profile'] as _i10.ProfileEndpoint)
                  .getNotificationPreferences(
            session,
            params['userId'],
          ),
        ),
        'updateNotificationPreferences': _i1.MethodConnector(
          name: 'updateNotificationPreferences',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'prefsData': _i1.ParameterDescription(
              name: 'prefsData',
              type: _i1.getType<Map<String, dynamic>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['profile'] as _i10.ProfileEndpoint)
                  .updateNotificationPreferences(
            session,
            params['userId'],
            params['prefsData'],
          ),
        ),
        'exportUserData': _i1.MethodConnector(
          name: 'exportUserData',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['profile'] as _i10.ProfileEndpoint).exportUserData(
            session,
            params['userId'],
          ),
        ),
        'deleteUserData': _i1.MethodConnector(
          name: 'deleteUserData',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['profile'] as _i10.ProfileEndpoint).deleteUserData(
            session,
            params['userId'],
          ),
        ),
      },
    );
    connectors['story'] = _i1.EndpointConnector(
      name: 'story',
      endpoint: endpoints['story']!,
      methodConnectors: {
        'getFeed': _i1.MethodConnector(
          name: 'getFeed',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['story'] as _i11.StoryEndpoint).getFeed(
            session,
            limit: params['limit'],
            offset: params['offset'],
          ),
        ),
        'getStory': _i1.MethodConnector(
          name: 'getStory',
          params: {
            'storyId': _i1.ParameterDescription(
              name: 'storyId',
              type: _i1.getType<int>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['story'] as _i11.StoryEndpoint).getStory(
            session,
            params['storyId'],
          ),
        ),
      },
    );
    connectors['stripeWebhook'] = _i1.EndpointConnector(
      name: 'stripeWebhook',
      endpoint: endpoints['stripeWebhook']!,
      methodConnectors: {
        'handleWebhook': _i1.MethodConnector(
          name: 'handleWebhook',
          params: {
            'payload': _i1.ParameterDescription(
              name: 'payload',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'signature': _i1.ParameterDescription(
              name: 'signature',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['stripeWebhook'] as _i12.StripeWebhookEndpoint)
                  .handleWebhook(
            session,
            params['payload'],
            params['signature'],
          ),
        )
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['greeting'] as _i13.GreetingEndpoint).hello(
            session,
            params['name'],
          ),
        )
      },
    );
  }
}
