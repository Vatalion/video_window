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
import 'package:video_window_client/src/protocol/greeting.dart' as _i3;
import 'protocol.dart' as _i4;

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
/// Placeholder for Epic 1 - Viewer Authentication
/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Placeholder: Send OTP for email authentication
  _i2.Future<Map<String, dynamic>> sendOtp(String email) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'sendOtp',
        {'email': email},
      );

  /// Placeholder: Verify OTP and create session
  _i2.Future<Map<String, dynamic>> verifyOtp(
    String email,
    String code,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'auth',
        'verifyOtp',
        {
          'email': email,
          'code': code,
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
/// Placeholder for Epic 12 - Checkout & Payment
/// {@category Endpoint}
class EndpointPayment extends _i1.EndpointRef {
  EndpointPayment(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'payment';

  /// Placeholder: Create Stripe checkout session
  _i2.Future<Map<String, dynamic>> createCheckoutSession(int orderId) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'payment',
        'createCheckoutSession',
        {'orderId': orderId},
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

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i3.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i3.Greeting>(
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
          _i4.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    health = EndpointHealth(this);
    auth = EndpointAuth(this);
    metrics = EndpointMetrics(this);
    offer = EndpointOffer(this);
    order = EndpointOrder(this);
    payment = EndpointPayment(this);
    story = EndpointStory(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointHealth health;

  late final EndpointAuth auth;

  late final EndpointMetrics metrics;

  late final EndpointOffer offer;

  late final EndpointOrder order;

  late final EndpointPayment payment;

  late final EndpointStory story;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'health': health,
        'auth': auth,
        'metrics': metrics,
        'offer': offer,
        'order': order,
        'payment': payment,
        'story': story,
        'greeting': greeting,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
