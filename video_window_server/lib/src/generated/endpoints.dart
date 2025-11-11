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
import '../endpoints/health_endpoint.dart' as _i2;
import '../endpoints/identity/auth_endpoint.dart' as _i3;
import '../endpoints/metrics_endpoint.dart' as _i4;
import '../endpoints/offers/offer_endpoint.dart' as _i5;
import '../endpoints/orders/order_endpoint.dart' as _i6;
import '../endpoints/payments/payment_endpoint.dart' as _i7;
import '../endpoints/story/story_endpoint.dart' as _i8;
import '../greeting_endpoint.dart' as _i9;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'health': _i2.HealthEndpoint()
        ..initialize(
          server,
          'health',
          null,
        ),
      'auth': _i3.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'metrics': _i4.MetricsEndpoint()
        ..initialize(
          server,
          'metrics',
          null,
        ),
      'offer': _i5.OfferEndpoint()
        ..initialize(
          server,
          'offer',
          null,
        ),
      'order': _i6.OrderEndpoint()
        ..initialize(
          server,
          'order',
          null,
        ),
      'payment': _i7.PaymentEndpoint()
        ..initialize(
          server,
          'payment',
          null,
        ),
      'story': _i8.StoryEndpoint()
        ..initialize(
          server,
          'story',
          null,
        ),
      'greeting': _i9.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
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
              (endpoints['health'] as _i2.HealthEndpoint).check(session),
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
              (endpoints['auth'] as _i3.AuthEndpoint).sendOtp(
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
              (endpoints['auth'] as _i3.AuthEndpoint).verifyOtp(
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
              (endpoints['auth'] as _i3.AuthEndpoint).refresh(
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
              (endpoints['auth'] as _i3.AuthEndpoint).logout(
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
              (endpoints['auth'] as _i3.AuthEndpoint).verifyAppleToken(
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
              (endpoints['auth'] as _i3.AuthEndpoint).verifyGoogleToken(
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
              (endpoints['auth'] as _i3.AuthEndpoint).sendRecovery(
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
              (endpoints['auth'] as _i3.AuthEndpoint).verifyRecovery(
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
              (endpoints['auth'] as _i3.AuthEndpoint).revokeRecovery(
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
              (endpoints['metrics'] as _i4.MetricsEndpoint).getMetrics(session),
        ),
        'getHealth': _i1.MethodConnector(
          name: 'getHealth',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['metrics'] as _i4.MetricsEndpoint).getHealth(session),
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
              (endpoints['offer'] as _i5.OfferEndpoint).submitOffer(
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
              (endpoints['order'] as _i6.OrderEndpoint).getOrder(
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
              (endpoints['order'] as _i6.OrderEndpoint).updateShipping(
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
              (endpoints['payment'] as _i7.PaymentEndpoint)
                  .createCheckoutSession(
            session,
            params['orderId'],
          ),
        )
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
              (endpoints['story'] as _i8.StoryEndpoint).getFeed(
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
              (endpoints['story'] as _i8.StoryEndpoint).getStory(
            session,
            params['storyId'],
          ),
        ),
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
              (endpoints['greeting'] as _i9.GreetingEndpoint).hello(
            session,
            params['name'],
          ),
        )
      },
    );
  }
}
