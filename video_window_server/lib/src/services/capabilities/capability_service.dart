import 'package:serverpod/serverpod.dart';
import '../../generated/capabilities/user_capabilities.dart';
import '../../generated/capabilities/capability_request.dart';
import '../../generated/capabilities/capability_type.dart';
import '../../generated/capabilities/capability_request_status.dart';
import '../../generated/capabilities/capability_review_state.dart';
import '../../generated/capabilities/capability_audit_event.dart';
import '../device_trust_service.dart';
import 'dart:convert';

/// Service for managing user capabilities and verification workflows
/// Implements Epic 2 - Capability Enablement & Verification
class CapabilityService {
  final Session _session;

  CapabilityService(this._session);

  /// Fetch or create user capabilities snapshot
  Future<UserCapabilities> getUserCapabilities(int userId) async {
    try {
      // Try to fetch existing capabilities
      final existing = await UserCapabilities.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId),
      );

      if (existing != null) {
        return existing;
      }

      // Create default capabilities for new user
      final now = DateTime.now().toUtc();
      final newCapabilities = UserCapabilities(
        userId: userId,
        canPublish: false,
        canCollectPayments: false,
        canFulfillOrders: false,
        reviewState: CapabilityReviewState.none,
        blockers: '{}',
        updatedAt: now,
        createdAt: now,
      );

      final inserted =
          await UserCapabilities.db.insertRow(_session, newCapabilities);
      return inserted;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get user capabilities for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Request a capability (idempotent)
  Future<CapabilityRequest> requestCapability({
    required int userId,
    required CapabilityType capability,
    required Map<String, String> context,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      // Check if request already exists (idempotency)
      final existing = await CapabilityRequest.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId) & t.capability.equals(capability),
      );

      if (existing != null) {
        // Return existing request (idempotent)
        _session.log(
          'Capability request already exists for user $userId, capability: $capability',
          level: LogLevel.info,
        );
        return existing;
      }

      // Create new request
      final request = CapabilityRequest(
        userId: userId,
        capability: capability,
        status: CapabilityRequestStatus.requested,
        metadata: jsonEncode(context),
        createdAt: now,
        updatedAt: now,
      );

      await CapabilityRequest.db.insertRow(_session, request);

      // Emit audit event
      await _emitAuditEvent(
        userId: userId,
        eventType: 'capability.requested',
        capability: capability,
        entryPoint: context['entryPoint'],
        deviceFingerprint: context['deviceFingerprint'],
        metadata: context,
      );

      // Update user capabilities review state
      await _updateReviewState(userId, CapabilityReviewState.pending);

      _session.log(
        'Capability request created for user $userId: $capability',
        level: LogLevel.info,
      );

      return request;
    } catch (e, stackTrace) {
      _session.log(
        'Failed to request capability for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check prerequisites and determine if capability can be auto-approved
  Future<bool> canAutoApprove({
    required int userId,
    required CapabilityType capability,
  }) async {
    try {
      final capabilities = await getUserCapabilities(userId);

      switch (capability) {
        case CapabilityType.publish:
          // Require identity verification
          return capabilities.identityVerifiedAt != null;

        case CapabilityType.collectPayments:
          // Require payout configuration and identity
          return capabilities.payoutConfiguredAt != null &&
              capabilities.identityVerifiedAt != null;

        case CapabilityType.fulfillOrders:
          // Require payment capability and trusted device
          if (!capabilities.canCollectPayments) {
            return false;
          }
          // Check device trust (AC2: Capabilities requiring trusted devices remain blocked until at least one device exceeds threshold)
          final deviceTrustService = DeviceTrustService(_session);
          return await deviceTrustService.hasTrustedDevice(userId);
      }
    } catch (e, stackTrace) {
      _session.log(
        'Failed to check auto-approve for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Update capability status (called by verification workflows)
  Future<void> updateCapability({
    required int userId,
    required CapabilityType capability,
    required bool enabled,
  }) async {
    try {
      final capabilities = await getUserCapabilities(userId);
      final now = DateTime.now().toUtc();

      // Update the appropriate capability flag
      switch (capability) {
        case CapabilityType.publish:
          capabilities.canPublish = enabled;
          if (enabled) {
            capabilities.identityVerifiedAt ??= now;
          }
          break;
        case CapabilityType.collectPayments:
          capabilities.canCollectPayments = enabled;
          if (enabled) {
            capabilities.payoutConfiguredAt ??= now;
          }
          break;
        case CapabilityType.fulfillOrders:
          capabilities.canFulfillOrders = enabled;
          if (enabled) {
            capabilities.fulfillmentEnabledAt ??= now;
          }
          break;
      }

      capabilities.updatedAt = now;
      await UserCapabilities.db.updateRow(_session, capabilities);

      // Emit audit event
      await _emitAuditEvent(
        userId: userId,
        eventType: enabled ? 'capability.approved' : 'capability.revoked',
        capability: capability,
        metadata: {},
      );

      _session.log(
        'Capability updated for user $userId: $capability = $enabled',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      _session.log(
        'Failed to update capability for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Internal: Update review state
  Future<void> _updateReviewState(
    int userId,
    CapabilityReviewState state,
  ) async {
    final capabilities = await getUserCapabilities(userId);
    capabilities.reviewState = state;
    capabilities.updatedAt = DateTime.now().toUtc();
    await UserCapabilities.db.updateRow(_session, capabilities);
  }

  /// Internal: Emit audit event
  Future<void> _emitAuditEvent({
    required int userId,
    required String eventType,
    CapabilityType? capability,
    String? entryPoint,
    String? deviceFingerprint,
    required Map<String, String> metadata,
  }) async {
    try {
      final event = CapabilityAuditEvent(
        userId: userId,
        eventType: eventType,
        capability: capability,
        entryPoint: entryPoint,
        deviceFingerprint: deviceFingerprint,
        metadata: jsonEncode(metadata),
        createdAt: DateTime.now().toUtc(),
      );

      await CapabilityAuditEvent.db.insertRow(_session, event);

      _session.log(
        'Audit event emitted: $eventType for user $userId',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      // Log but don't throw - audit failures shouldn't break the flow
      _session.log(
        'Failed to emit audit event: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get blockers for a capability
  Future<Map<String, String>> getBlockers(
    int userId,
    CapabilityType capability,
  ) async {
    try {
      final capabilities = await getUserCapabilities(userId);

      switch (capability) {
        case CapabilityType.publish:
          if (!capabilities.canPublish) {
            if (capabilities.identityVerifiedAt == null) {
              return {'publish': 'Identity verification required'};
            }
          }
          break;

        case CapabilityType.collectPayments:
          if (!capabilities.canCollectPayments) {
            final blockers = <String, String>{};
            if (capabilities.identityVerifiedAt == null) {
              blockers['identity'] = 'Identity verification required';
            }
            if (capabilities.payoutConfiguredAt == null) {
              blockers['payout'] = 'Payout account configuration required';
            }
            return blockers;
          }
          break;

        case CapabilityType.fulfillOrders:
          if (!capabilities.canFulfillOrders) {
            final blockers = <String, String>{};
            if (!capabilities.canCollectPayments) {
              blockers['payment'] = 'Payment capability must be enabled first';
            }
            // Check device trust blocker (may be set by DeviceTrustService)
            final blockersMap =
                jsonDecode(capabilities.blockers) as Map<String, dynamic>? ??
                    {};
            if (blockersMap.containsKey('device_trust')) {
              blockers['device_trust'] = blockersMap['device_trust'] as String;
            }
            return blockers;
          }
          break;
      }

      return {};
    } catch (e, stackTrace) {
      _session.log(
        'Failed to get blockers for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }
}
