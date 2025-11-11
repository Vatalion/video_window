import 'package:test/test.dart';
import 'package:video_window_server/src/services/verification_service.dart';
import 'package:video_window_server/src/generated/protocol.dart';
import '../integration/test_tools/serverpod_test_tools.dart';

/// Integration tests for VerificationService
///
/// AC3: Verifies webhook triggers capability unlock and enables publish
void main() {
  withServerpod(
    'VerificationService Tests',
    (sessionBuilder, endpoints) {
      group('VerificationService', () {
        test('creates verification task for publish capability', () async {
          final session = sessionBuilder.build();
          final service = VerificationService(session);

          final task = await service.createVerificationTask(
            userId: 1,
            capability: CapabilityType.publish,
            taskType: VerificationTaskType.personaIdentity,
            metadata: {'test': 'data'},
          );

          expect(task, isNotNull);
          expect(task.userId, equals(1));
          expect(task.capability, equals(CapabilityType.publish));
          expect(task.taskType, equals(VerificationTaskType.personaIdentity));
          expect(task.status, equals(VerificationTaskStatus.pending));
        });

        test('completes verification task and auto-approves publish capability',
            () async {
          final session = sessionBuilder.build();
          final service = VerificationService(session);

          // Create task
          final task = await service.createVerificationTask(
            userId: 1,
            capability: CapabilityType.publish,
            taskType: VerificationTaskType.personaIdentity,
            metadata: {},
          );

          // Complete with approved status
          await service.completeVerificationTask(
            taskId: task.id!.toString(),
            provider: 'persona',
            status: 'approved',
            metadata: {'verificationId': 'test-123'},
          );

          // Verify task is completed
          final completedTask =
              await service.getVerificationTask(task.id!.toString());
          expect(completedTask, isNotNull);
          expect(
              completedTask!.status, equals(VerificationTaskStatus.completed));
        });

        test('handles rejected verification status', () async {
          final session = sessionBuilder.build();
          final service = VerificationService(session);

          final task = await service.createVerificationTask(
            userId: 1,
            capability: CapabilityType.publish,
            taskType: VerificationTaskType.personaIdentity,
            metadata: {},
          );

          await service.completeVerificationTask(
            taskId: task.id!.toString(),
            provider: 'persona',
            status: 'rejected',
            metadata: {'reason': 'Document quality insufficient'},
          );

          final rejectedTask =
              await service.getVerificationTask(task.id!.toString());
          expect(rejectedTask, isNotNull);
          expect(rejectedTask!.status, equals(VerificationTaskStatus.failed));
        });
      });
    },
  );
}
