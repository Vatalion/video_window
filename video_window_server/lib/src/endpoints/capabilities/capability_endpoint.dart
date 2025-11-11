import 'package:serverpod/serverpod.dart';
import '../../services/capabilities/capability_service.dart';
import '../../services/auth/rate_limit_service.dart';
import '../../generated/capabilities/capability_status_response.dart';
import '../../generated/capabilities/capability_request_dto.dart';
import '../../generated/capabilities/capability_request.dart';
import '../../generated/capabilities/capability_type.dart';

/// Capability endpoint for managing user capability requests and status
/// Implements Story 2-1: Capability Enablement Request Flow
class CapabilityEndpoint extends Endpoint {
  @override
  String get name => 'capabilities';

  /// Get current capability status for user
  /// Cached for ≤10 seconds per user
  ///
  /// AC1: Capability Center screen surfaces current capability status, blockers, and CTAs
  Future<CapabilityStatusResponse> getStatus(
    Session session,
    int userId,
  ) async {
    try {
      final capabilityService = CapabilityService(session);
      final capabilities = await capabilityService.getUserCapabilities(userId);

      // Get blockers for each capability
      final publishBlockers = await capabilityService.getBlockers(
        userId,
        CapabilityType.publish,
      );
      final paymentBlockers = await capabilityService.getBlockers(
        userId,
        CapabilityType.collectPayments,
      );
      final fulfillmentBlockers = await capabilityService.getBlockers(
        userId,
        CapabilityType.fulfillOrders,
      );

      // Merge all blockers
      final allBlockers = <String, String>{
        ...publishBlockers,
        ...paymentBlockers,
        ...fulfillmentBlockers,
      };

      session.log(
        'Capability status fetched for user $userId',
        level: LogLevel.info,
      );

      return CapabilityStatusResponse(
        userId: userId,
        canPublish: capabilities.canPublish,
        canCollectPayments: capabilities.canCollectPayments,
        canFulfillOrders: capabilities.canFulfillOrders,
        identityVerifiedAt: capabilities.identityVerifiedAt,
        payoutConfiguredAt: capabilities.payoutConfiguredAt,
        fulfillmentEnabledAt: capabilities.fulfillmentEnabledAt,
        reviewState: capabilities.reviewState,
        blockers: allBlockers,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to get capability status for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Request a capability (idempotent)
  /// Rate limited: 5 requests per minute per user
  ///
  /// AC2: Inline prompts detect missing capability and open guided checklist
  /// AC3: Submitting a request calls POST /capabilities/request, persists metadata, idempotent
  /// AC4: Audit event capability.requested is emitted
  /// AC5: Analytics event capability_request_submitted is recorded
  Future<CapabilityStatusResponse> requestCapability(
    Session session,
    int userId,
    CapabilityRequestDto request,
  ) async {
    try {
      // Check rate limit: 5/min per user
      final rateLimitService = RateLimitService(session);
      // Extract real IP from request headers (X-Forwarded-For, X-Real-IP, or connection info)
      final ipAddress = session.httpRequest.headers['x-forwarded-for']?.first ??
          session.httpRequest.headers['x-real-ip']?.first ??
          session.httpRequest.connectionInfo?.remoteAddress.address ??
          '0.0.0.0';

      final rateLimitResult = await rateLimitService.checkRateLimit(
        identifier: 'capability_request_$userId',
        ipAddress: ipAddress,
        action: 'request_capability',
      );

      if (!rateLimitResult.allowed) {
        session.log(
          'Rate limit exceeded for capability request: user $userId',
          level: LogLevel.warning,
        );
        throw Exception('Too many requests: ${rateLimitResult.reason}');
      }

      final capabilityService = CapabilityService(session);

      // Create or retrieve capability request (idempotent)
      await capabilityService.requestCapability(
        userId: userId,
        capability: request.capability,
        context: request.context,
      );

      // Check if can auto-approve
      final canAutoApprove = await capabilityService.canAutoApprove(
        userId: userId,
        capability: request.capability,
      );

      if (canAutoApprove) {
        // Auto-approve and enable capability
        await capabilityService.updateCapability(
          userId: userId,
          capability: request.capability,
          enabled: true,
        );

        session.log(
          'Capability auto-approved for user $userId: ${request.capability}',
          level: LogLevel.info,
        );
      }

      // AC5: Emit analytics event capability_request_submitted
      try {
        session.log(
          'Analytics event: capability_request_submitted - '
          'userId=$userId, capability=${request.capability}, entryPoint=${request.context['entryPoint']}',
          level: LogLevel.info,
        );
        // TODO: Replace with actual analytics service when available
        // await analyticsService.track('capability_request_submitted', {
        //   'userId': userId,
        //   'capability': request.capability.toString(),
        //   'entryPoint': request.context['entryPoint'],
        //   'timestamp': DateTime.now().toIso8601String(),
        //   'success': true,
        // });
      } catch (e) {
        // Don't fail request if analytics fails
        session.log('Failed to emit analytics event: $e',
            level: LogLevel.warning);
      }

      // Return updated status
      return await getStatus(session, userId);
    } catch (e, stackTrace) {
      session.log(
        'Failed to request capability for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get capability request history for user
  Future<List<CapabilityRequest>> getRequests(
    Session session,
    int userId,
  ) async {
    try {
      // Query capability requests for user
      final requests = await CapabilityRequest.db.find(
        session,
        where: (t) => t.userId.equals(userId),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );

      session.log(
        'Capability requests fetched for user $userId: ${requests.length} requests',
        level: LogLevel.info,
      );

      return requests;
    } catch (e, stackTrace) {
      session.log(
        'Failed to get capability requests for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
