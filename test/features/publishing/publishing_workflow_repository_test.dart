import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/publishing/data/repositories/publishing_workflow_repository_impl.dart';
import 'package:video_window/features/publishing/data/services/publishing_workflow_service.dart';
import 'package:video_window/features/publishing/data/services/content_processing_service.dart';
import 'package:video_window/features/publishing/domain/entities/publishing_workflow.dart';
import 'package:video_window/features/publishing/domain/entities/status_change.dart';
import 'package:video_window/features/publishing/domain/enums/publishing_status.dart';

void main() {
  group('PublishingWorkflowRepositoryImpl', () {
    late PublishingWorkflowRepositoryImpl repository;
    late PublishingWorkflowService workflowService;
    late ContentProcessingService processingService;

    setUp(() {
      workflowService = PublishingWorkflowService();
      processingService = ContentProcessingService();
      repository = PublishingWorkflowRepositoryImpl(
        workflowService: workflowService,
        processingService: processingService,
      );
    });

    test('should create a workflow', () async {
      // Arrange
      final workflow = PublishingWorkflow(
        id: 'workflow1',
        contentId: 'content1',
        currentStatus: PublishingStatus.draft,
        statusHistory: [],
      );

      // Act
      final createdWorkflow = await repository.createWorkflow(workflow);

      // Assert
      expect(createdWorkflow, equals(workflow));
    });

    test('should get a workflow by ID', () async {
      // Arrange
      final workflow = PublishingWorkflow(
        id: 'workflow1',
        contentId: 'content1',
        currentStatus: PublishingStatus.draft,
        statusHistory: [],
      );
      await repository.createWorkflow(workflow);

      // Act
      final retrievedWorkflow = await repository.getWorkflow('workflow1');

      // Assert
      expect(retrievedWorkflow, equals(workflow));
    });

    test('should get workflows by status', () async {
      // Arrange
      final workflow1 = PublishingWorkflow(
        id: 'workflow1',
        contentId: 'content1',
        currentStatus: PublishingStatus.draft,
        statusHistory: [],
      );
      final workflow2 = PublishingWorkflow(
        id: 'workflow2',
        contentId: 'content2',
        currentStatus: PublishingStatus.draft,
        statusHistory: [],
      );
      final workflow3 = PublishingWorkflow(
        id: 'workflow3',
        contentId: 'content3',
        currentStatus: PublishingStatus.published,
        statusHistory: [],
      );
      
      await repository.createWorkflow(workflow1);
      await repository.createWorkflow(workflow2);
      await repository.createWorkflow(workflow3);

      // Act
      final draftWorkflows = await repository.getWorkflowsByStatus(PublishingStatus.draft);

      // Assert
      expect(draftWorkflows.length, equals(2));
      expect(draftWorkflows.contains(workflow1), isTrue);
      expect(draftWorkflows.contains(workflow2), isTrue);
    });

    test('should transition status from draft to review', () async {
      // Arrange
      final workflow = PublishingWorkflow(
        id: 'workflow1',
        contentId: 'content1',
        currentStatus: PublishingStatus.draft,
        statusHistory: [],
      );
      await repository.createWorkflow(workflow);

      // Act
      final updatedWorkflow = await repository.transitionStatus(
        'workflow1',
        PublishingStatus.review,
        'user123',
        notes: 'Ready for review',
      );

      // Assert
      expect(updatedWorkflow.currentStatus, equals(PublishingStatus.review));
      expect(updatedWorkflow.statusHistory.length, equals(1));
      expect(updatedWorkflow.statusHistory.first.fromStatus, equals(PublishingStatus.draft));
      expect(updatedWorkflow.statusHistory.first.toStatus, equals(PublishingStatus.review));
      expect(updatedWorkflow.statusHistory.first.userId, equals('user123'));
      expect(updatedWorkflow.statusHistory.first.notes, equals('Ready for review'));
    });

    test('should delete a workflow', () async {
      // Arrange
      final workflow = PublishingWorkflow(
        id: 'workflow1',
        contentId: 'content1',
        currentStatus: PublishingStatus.draft,
        statusHistory: [],
      );
      await repository.createWorkflow(workflow);

      // Act
      final result = await repository.deleteWorkflow('workflow1');

      // Assert
      expect(result, isTrue);
      expect(await repository.getWorkflow('workflow1'), isNull);
    });
  });
}