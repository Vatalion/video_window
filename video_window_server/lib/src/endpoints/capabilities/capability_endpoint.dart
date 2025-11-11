import 'package:serverpod/serverpod.dart';
import '../../services/capabilities/capability_service.dart';
import '../../services/verification_service.dart';
import '../../services/auth/rate_limit_service.dart';
import '../../services/stripe/stripe_service.dart';
import '../../generated/capabilities/capability_status_response.dart';
import '../../generated/capabilities/capability_request_dto.dart';
import '../../generated/capabilities/capability_request.dart';
import '../../generated/capabilities/capability_type.dart';
import '../../generated/capabilities/verification_task.dart';

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
      final ipAddress = _getClientIp(session);

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
      // Using structured logging for MVP (ready for analytics service integration)
      _emitAnalyticsEvent(
        session: session,
        eventName: 'capability_request_submitted',
        properties: {
          'user_id': userId,
          'capability': request.capability.toString(),
          'entry_point': request.context['entryPoint'] ?? 'unknown',
          'device_fingerprint': request.context['deviceFingerprint'],
          'request_timestamp': DateTime.now().toIso8601String(),
          'result': 'success',
          'auto_approved': canAutoApprove,
        },
      );

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

  // Helper methods

  /// Emit analytics event with structured logging
  ///
  /// AC5: Analytics events are recorded for capability requests
  /// Uses structured logging that can be easily integrated with analytics service
  void _emitAnalyticsEvent({
    required Session session,
    required String eventName,
    required Map<String, dynamic> properties,
  }) {
    try {
      // Structured logging format: [ANALYTICS] event_name | property1=value1 | property2=value2
      final propertiesString =
          properties.entries.map((e) => '${e.key}=${e.value}').join(' | ');

      session.log(
        '[ANALYTICS] $eventName | $propertiesString',
        level: LogLevel.info,
      );

      // Future integration point:
      // When analytics service is available, uncomment and implement:
      // await analyticsService.track(eventName, properties);
    } catch (e) {
      session.log(
        'Failed to emit analytics event $eventName: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Complete a verification task (webhook endpoint)
  ///
  /// AC3: Persona webhook updates verification_task and toggles identityVerifiedAt when approved
  /// AC4: Validates webhook signature for security
  /// AC6: Emits audit event verification.completed with provider metadata, redacting PII
  ///
  /// POST /capabilities/tasks/{id}/complete
  Future<void> completeVerificationTask(
    Session session,
    int taskId,
    Map<String, dynamic> webhookPayload,
  ) async {
    try {
      final verificationService = VerificationService(session);

      // Extract webhook payload
      final provider = webhookPayload['provider'] as String? ?? 'unknown';
      final status = webhookPayload['status'] as String? ?? 'unknown';
      final metadata =
          webhookPayload['metadata'] as Map<String, dynamic>? ?? {};
      final signature = webhookPayload['signature'] as String?;

      // Complete the verification task
      await verificationService.completeVerificationTask(
        taskId: taskId.toString(),
        provider: provider,
        status: status,
        metadata: metadata,
        webhookSignature: signature,
      );

      session.log(
        'Verification task completed via webhook: $taskId, provider: $provider, status: $status',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to complete verification task $taskId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get verification task status
  ///
  /// GET /capabilities/tasks/{id}
  Future<VerificationTask?> getVerificationTask(
    Session session,
    int taskId,
  ) async {
    try {
      final verificationService = VerificationService(session);
      return await verificationService.getVerificationTask(taskId.toString());
    } catch (e, stackTrace) {
      session.log(
        'Failed to get verification task $taskId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get Stripe onboarding link for payout activation
  ///
  /// AC1: Provides Stripe Express onboarding URL for payout setup
  /// POST /capabilities/stripe/onboarding-link
  Future<Map<String, dynamic>> getStripeOnboardingLink(
    Session session,
    int userId,
    String returnUrl,
  ) async {
    try {
      final stripeService = StripeService(session);
      final onboardingUrl = await stripeService.createOnboardingLink(
        userId: userId,
        returnUrl: returnUrl,
      );

      session.log(
        'Stripe onboarding link generated for user $userId',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'onboardingUrl': onboardingUrl,
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to generate Stripe onboarding link for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Extract client IP address from session
  ///
  /// NOTE: Serverpod 2.9.1 Session object doesn't expose HTTP request details
  /// (headers, connectionInfo) through its public API. IP extraction requires
  /// either:
  /// 1. Upgrade to newer Serverpod version with request context access
  /// 2. Use API gateway/proxy that injects IP into request metadata
  /// 3. Custom middleware to capture IP before endpoint execution
  ///
  /// For MVP: Using placeholder that allows rate limiting by user ID.
  /// Production deployment should use API gateway (e.g., AWS ALB, nginx)
  /// to inject client IP into a custom header that can be read via metadata.
  String _getClientIp(Session session) {
    // Placeholder IP - rate limiting currently relies on user_id only
    // TODO: Extract from session metadata when available in production setup
    // Example: session.serverpod.metadata['client-ip'] ?? '0.0.0.0'
    return '0.0.0.0';
  }
}
