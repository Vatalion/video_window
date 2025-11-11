import 'package:serverpod/serverpod.dart';
import '../../services/capabilities/capability_service.dart';
import '../../generated/capabilities/capability_type.dart';

/// Payment processing endpoint via Stripe
/// Implements Epic 12 - Checkout & Payment
/// Story 2-3: Guards checkout with canCollectPayments check
class PaymentEndpoint extends Endpoint {
  @override
  String get name => 'payment';

  /// Create Stripe checkout session
  ///
  /// AC5: Guards checkout creation with canCollectPayments verification
  /// Returns error with blocker summary if capability not active
  Future<Map<String, dynamic>> createCheckoutSession(
    Session session,
    int userId,
    int orderId,
  ) async {
    try {
      // AC5: Guard checkout with canCollectPayments check
      final capabilityService = CapabilityService(session);
      final capabilities = await capabilityService.getUserCapabilities(userId);

      if (!capabilities.canCollectPayments) {
        // Get blockers for payment capability
        final blockers = await capabilityService.getBlockers(
          userId,
          CapabilityType.collectPayments,
        );

        session.log(
          'Checkout blocked for user $userId: payment capability not active',
          level: LogLevel.info,
        );

        return {
          'success': false,
          'error': 'PAYMENT_CAPABILITY_REQUIRED',
          'message':
              'Payment collection capability must be enabled before checkout',
          'blockers': blockers,
          'canCollectPayments': false,
        };
      }

      // TODO: Implement Stripe checkout session creation (Story 12.1)
      // For now, return placeholder
      return {
        'success': true,
        'message':
            'Checkout session creation - to be implemented in Story 12.1',
        'orderId': orderId,
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to create checkout session: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Failed to create checkout session',
      };
    }
  }
}
