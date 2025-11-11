import 'package:test/test.dart';
import 'package:video_window_server/src/generated/capabilities/capability_type.dart';
import 'package:video_window_server/src/generated/capabilities/capability_request_dto.dart';
import 'package:video_window_server/src/generated/capabilities/capability_request.dart';
import 'package:video_window_server/src/generated/capabilities/capability_audit_event.dart';
import 'package:video_window_server/src/generated/capabilities/user_capabilities.dart';
import 'package:video_window_server/src/services/capabilities/capability_service.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Integration test covering capability request submission → status polling → unlock event
///
/// AC3: Integration test verifying:
/// - Request submission
/// - Idempotency
/// - Status polling
/// - Rate limiting
/// - Blocker resolution
/// - Auto-approval
/// - Audit event emission
///
/// To run: dart test test/integration/capability_flow_test.dart
void main() {
  withServerpod(
    'Capability Flow Integration Tests',
    (sessionBuilder, endpoints) {
      group('Request Submission and Idempotency', () {
        test('request capability creates record with idempotency', () async {
          const testUserId =
              30001; // Unique ID per test to avoid rate limiting conflicts

          // 1. Call requestCapability endpoint
          final request1 = CapabilityRequestDto(
            capability: CapabilityType.publish,
            context: {
              'entryPoint': 'publish_flow',
              'deviceFingerprint': 'test-device-001',
            },
          );

          final response1 = await endpoints.capability.requestCapability(
            sessionBuilder,
            testUserId,
            request1,
          );

          // 2. Verify capability_requests record created
          expect(response1.userId, equals(testUserId));
          expect(response1.canPublish, isFalse,
              reason: 'Should not be auto-approved without prerequisites');

          // Build session for database access
          final session = sessionBuilder.build();
          final requestsInDb = await CapabilityRequest.db.find(
            session,
            where: (t) =>
                t.userId.equals(testUserId) &
                t.capability.equals(CapabilityType.publish),
          );
          expect(requestsInDb.length, equals(1),
              reason: 'Should create exactly one request record');

          // 3. Call again with same params (idempotency test)
          final response2 = await endpoints.capability.requestCapability(
            sessionBuilder,
            testUserId,
            request1,
          );

          // 4. Verify no duplicate created (idempotency)
          final requestsAfter = await CapabilityRequest.db.find(
            session,
            where: (t) =>
                t.userId.equals(testUserId) &
                t.capability.equals(CapabilityType.publish),
          );
          expect(requestsAfter.length, equals(1),
              reason: 'Idempotent requests should not create duplicates');

          // Responses should be similar
          expect(response2.userId, equals(response1.userId));
          expect(response2.canPublish, equals(response1.canPublish));

          // 5. Verify audit event emitted
          final auditEvents = await CapabilityAuditEvent.db.find(
            session,
            where: (t) =>
                t.userId.equals(testUserId) &
                t.eventType.equals('capability.requested'),
          );
          expect(auditEvents.length, greaterThanOrEqualTo(1),
              reason: 'Audit event should be emitted for capability request');
          expect(auditEvents.first.capability, equals(CapabilityType.publish));
          expect(auditEvents.first.entryPoint, equals('publish_flow'));
        });
      });

      group('Status Polling and Updates', () {
        test('status polling returns updated capability flags', () async {
          final session = sessionBuilder.build();
          const testUserId =
              30002; // Unique ID per test to avoid rate limiting conflicts

          // 0. Cleanup: Delete any existing capability records for this test user
          final existingCaps = await UserCapabilities.db.find(
            session,
            where: (t) => t.userId.equals(testUserId),
          );
          for (var cap in existingCaps) {
            await UserCapabilities.db.deleteRow(session, cap);
          }
          final existingReqs = await CapabilityRequest.db.find(
            session,
            where: (t) => t.userId.equals(testUserId),
          );
          for (var req in existingReqs) {
            await CapabilityRequest.db.deleteRow(session, req);
          }

          // 1. Request capability (without prerequisites)
          final request = CapabilityRequestDto(
            capability: CapabilityType.publish,
            context: {
              'entryPoint': 'capability_center',
              'deviceFingerprint': 'test-device-002',
            },
          );

          await endpoints.capability.requestCapability(
            sessionBuilder,
            testUserId,
            request,
          );

          // 2. Poll getStatus endpoint (should be disabled)
          var status1 =
              await endpoints.capability.getStatus(sessionBuilder, testUserId);
          expect(status1.canPublish, isFalse,
              reason: 'Capability should be disabled without prerequisites');
          expect(status1.blockers, isNotEmpty,
              reason: 'Should return blockers when prerequisites not met');

          // 3. Simulate prerequisite completion (enable identity verification)
          final capabilityService = CapabilityService(session);
          final capabilities =
              await capabilityService.getUserCapabilities(testUserId);
          capabilities.identityVerifiedAt = DateTime.now().toUtc();
          await UserCapabilities.db.updateRow(session, capabilities);

          // Manually trigger capability update (simulate auto-approval)
          await capabilityService.updateCapability(
            userId: testUserId,
            capability: CapabilityType.publish,
            enabled: true,
          );

          // 4. Poll again
          var status2 =
              await endpoints.capability.getStatus(sessionBuilder, testUserId);

          // 5. Verify capability flag updated
          expect(status2.canPublish, isTrue,
              reason: 'Capability should be enabled after prerequisites met');
          expect(status2.identityVerifiedAt, isNotNull);
        });
      });

      group('Auto-Approval and Audit Events', () {
        test('capability unlock triggers audit event', () async {
          final session = sessionBuilder.build();
          const testUserId =
              30003; // Unique ID per test to avoid rate limiting conflicts

          // 1. Complete prerequisites first (set identity verification)
          final capabilityService = CapabilityService(session);
          final capabilities =
              await capabilityService.getUserCapabilities(testUserId);
          capabilities.identityVerifiedAt = DateTime.now().toUtc();
          await UserCapabilities.db.updateRow(session, capabilities);

          // 2. Request capability (should trigger auto-approval)
          final request = CapabilityRequestDto(
            capability: CapabilityType.publish,
            context: {
              'entryPoint': 'publish_flow',
              'deviceFingerprint': 'test-device-003',
            },
          );

          final response = await endpoints.capability.requestCapability(
            sessionBuilder,
            testUserId,
            request,
          );

          // 3. Verify capability.approved event emitted
          final approvalEvents = await CapabilityAuditEvent.db.find(
            session,
            where: (t) =>
                t.userId.equals(testUserId) &
                t.eventType.equals('capability.approved'),
          );
          expect(approvalEvents.length, greaterThanOrEqualTo(1),
              reason: 'Audit event should be emitted when capability approved');
          expect(
              approvalEvents.first.capability, equals(CapabilityType.publish));

          // 4. Verify capability flag set to true
          expect(response.canPublish, isTrue,
              reason:
                  'Capability should be auto-approved when prerequisites met');

          // 5. Verify timestamps populated
          expect(response.identityVerifiedAt, isNotNull);
        });
      });

      group('Rate Limiting', () {
        test('rate limiting prevents spam requests', () async {
          const testUserId =
              30004; // Unique ID per test to avoid rate limiting conflicts

          // 1. Submit 5 capability requests rapidly
          for (var i = 0; i < 5; i++) {
            try {
              await endpoints.capability.requestCapability(
                sessionBuilder,
                testUserId,
                CapabilityRequestDto(
                  capability: CapabilityType.publish,
                  context: {
                    'entryPoint': 'test_rate_limit_$i',
                    'deviceFingerprint': 'test-device-004',
                  },
                ),
              );
            } catch (e) {
              // Some requests may fail due to rate limiting
              // This is expected behavior
            }
          }

          // 2. 6th request should fail with rate limit error
          var rateLimitExceeded = false;
          try {
            await endpoints.capability.requestCapability(
              sessionBuilder,
              testUserId,
              CapabilityRequestDto(
                capability: CapabilityType.publish,
                context: {
                  'entryPoint': 'test_rate_limit_6',
                  'deviceFingerprint': 'test-device-004',
                },
              ),
            );
          } catch (e) {
            if (e.toString().contains('Too many requests') ||
                e.toString().contains('rate limit')) {
              rateLimitExceeded = true;
            }
          }

          expect(rateLimitExceeded, isTrue,
              reason: 'Should enforce rate limit after 5 requests per minute');

          // Note: Testing window reset would require waiting 60 seconds
          // which is impractical for automated tests
          // Rate limit functionality is thoroughly tested in rate_limit_service_test.dart
        });
      });

      group('Blocker Resolution Flow', () {
        test('blockers returned when prerequisites not met', () async {
          final session = sessionBuilder.build();
          const testUserId =
              30005; // Unique ID per test to avoid rate limiting conflicts

          // NOTE: This test may fail if run immediately after other tests due to
          // IP-level rate limiting (20 requests per 5 minutes per IP).
          // If it fails, wait 5 minutes or flush Redis to clear rate limit state.

          // 0. Cleanup: Delete any existing capability records for this test user
          final existingCaps = await UserCapabilities.db.find(
            session,
            where: (t) => t.userId.equals(testUserId),
          );
          for (var cap in existingCaps) {
            await UserCapabilities.db.deleteRow(session, cap);
          }
          final existingReqs = await CapabilityRequest.db.find(
            session,
            where: (t) => t.userId.equals(testUserId),
          );
          for (var req in existingReqs) {
            await CapabilityRequest.db.deleteRow(session, req);
          }

          // 1. Request capability without prerequisites
          final request = CapabilityRequestDto(
            capability: CapabilityType.collectPayments,
            context: {
              'entryPoint': 'checkout_flow',
              'deviceFingerprint': 'test-device-005',
            },
          );

          await endpoints.capability.requestCapability(
            sessionBuilder,
            testUserId,
            request,
          );

          // 2. Verify getStatus returns appropriate blockers
          var status1 =
              await endpoints.capability.getStatus(sessionBuilder, testUserId);
          expect(status1.canCollectPayments, isFalse);
          expect(status1.blockers, isNotEmpty,
              reason: 'Should return blockers for missing prerequisites');
          expect(
            status1.blockers.containsKey('identity') ||
                status1.blockers.containsKey('payout'),
            isTrue,
            reason: 'Should indicate identity or payout blocker',
          );

          // 3. Complete one prerequisite (identity verification)
          final capabilityService = CapabilityService(session);
          final capabilities =
              await capabilityService.getUserCapabilities(testUserId);
          capabilities.identityVerifiedAt = DateTime.now().toUtc();
          await UserCapabilities.db.updateRow(session, capabilities);

          // 4. Verify blocker partially removed (still need payout config)
          var status2 =
              await endpoints.capability.getStatus(sessionBuilder, testUserId);
          expect(status2.canCollectPayments, isFalse,
              reason: 'Still need payout configuration');

          // 5. Complete all prerequisites (payout configuration)
          capabilities.payoutConfiguredAt = DateTime.now().toUtc();
          await UserCapabilities.db.updateRow(session, capabilities);

          // Request again to trigger auto-approval
          await endpoints.capability.requestCapability(
            sessionBuilder,
            testUserId,
            request,
          );

          // 6. Verify capability auto-approved
          var status3 =
              await endpoints.capability.getStatus(sessionBuilder, testUserId);
          expect(status3.canCollectPayments, isTrue,
              reason: 'Should be auto-approved when all prerequisites met');
          expect(status3.blockers, isEmpty,
              reason: 'No blockers should remain after approval');
        });
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
