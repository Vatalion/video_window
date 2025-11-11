import 'package:serverpod/serverpod.dart';
import '../../services/stripe/stripe_service.dart';

/// Stripe webhook endpoint for handling payout onboarding events
/// Implements Story 2-3: Payout & Compliance Activation
class StripeWebhookEndpoint extends Endpoint {
  @override
  String get name => 'webhooks/stripe';

  /// Handle Stripe webhook events
  ///
  /// AC2: Processes Stripe Express onboarding webhooks
  /// AC4: Updates verification tasks and capability status
  Future<Map<String, dynamic>> handleWebhook(
    Session session,
    String payload,
    String signature,
  ) async {
    try {
      final stripeService = StripeService(session);
      await stripeService.handleWebhook(
        payload: payload,
        signature: signature,
      );

      session.log(
        'Stripe webhook processed successfully',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message': 'Webhook processed',
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to process Stripe webhook: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
