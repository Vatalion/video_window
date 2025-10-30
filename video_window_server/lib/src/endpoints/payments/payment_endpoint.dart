import 'package:serverpod/serverpod.dart';

/// Payment processing endpoint via Stripe
/// Placeholder for Epic 12 - Checkout & Payment
class PaymentEndpoint extends Endpoint {
  @override
  String get name => 'payment';

  /// Placeholder: Create Stripe checkout session
  Future<Map<String, dynamic>> createCheckoutSession(
    Session session,
    int orderId,
  ) async {
    // TODO: Implement Stripe checkout (Story 12.1)
    return {
      'success': false,
      'message': 'Not implemented - placeholder endpoint',
    };
  }
}
