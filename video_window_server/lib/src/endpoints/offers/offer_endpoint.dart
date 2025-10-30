import 'package:serverpod/serverpod.dart';

/// Offer submission endpoint for marketplace
/// Placeholder for Epic 9 - Offer Submission
class OfferEndpoint extends Endpoint {
  @override
  String get name => 'offer';

  /// Placeholder: Submit offer on story
  Future<Map<String, dynamic>> submitOffer(
    Session session,
    int storyId,
    double amount,
  ) async {
    // TODO: Implement offer submission (Story 9.1)
    return {
      'success': false,
      'message': 'Not implemented - placeholder endpoint',
    };
  }
}
