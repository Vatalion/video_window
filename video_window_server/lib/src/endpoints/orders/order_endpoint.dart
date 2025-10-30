import 'package:serverpod/serverpod.dart';

/// Order management endpoint
/// Placeholder for Epic 13 - Shipping & Tracking
class OrderEndpoint extends Endpoint {
  @override
  String get name => 'order';

  /// Placeholder: Get order details
  Future<Map<String, dynamic>?> getOrder(Session session, int orderId) async {
    // TODO: Implement order retrieval (Story 13.1)
    return null;
  }

  /// Placeholder: Update shipping info
  Future<Map<String, dynamic>> updateShipping(
    Session session,
    int orderId,
    String trackingNumber,
  ) async {
    // TODO: Implement shipping update (Story 13.2)
    return {
      'success': false,
      'message': 'Not implemented - placeholder endpoint',
    };
  }
}
