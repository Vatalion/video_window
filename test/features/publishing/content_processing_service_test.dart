import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/publishing/data/services/content_processing_service.dart';
import 'package:video_window/features/publishing/domain/entities/publishing_workflow.dart';
import 'package:video_window/features/publishing/domain/enums/publishing_status.dart';

void main() {
  group('ContentProcessingService', () {
    late ContentProcessingService processingService;

    setUp(() {
      processingService = ContentProcessingService();
    });

    test('should process content successfully', () async {
      // Arrange
      final workflow = PublishingWorkflow(
        id: 'workflow1',
        contentId: 'content1',
        currentStatus: PublishingStatus.draft,
        statusHistory: [],
      );

      // Act
      final result = await processingService.processContent(workflow);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.message, equals('Content processing completed successfully'));
    });

    test('should track processing status', () async {
      // Arrange
      final workflow = PublishingWorkflow(
        id: 'workflow1',
        contentId: 'content1',
        currentStatus: PublishingStatus.draft,
        statusHistory: [],
      );

      // Act
      final result = await processingService.processContent(workflow);
      final status = processingService.getProcessingStatus('workflow1');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(status, isNotNull);
      expect(status!.status, equals(ProcessingState.completed));
      expect(status.progress, equals(100.0));
      expect(status.message, equals('Content processing successful'));
    });

    test('should return null for non-existent processing status', () {
      // Act
      final status = processingService.getProcessingStatus('non-existent');

      // Assert
      expect(status, isNull);
    });

    test('should get processing queue', () async {
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

      // Add items to queue by starting processing
      processingService.processContent(workflow1);
      processingService.processContent(workflow2);

      // Act
      final queue = processingService.getProcessingQueue();

      // Assert
      expect(queue.length, equals(2));
      expect(queue.contains('workflow1'), isTrue);
      expect(queue.contains('workflow2'), isTrue);
    });
  });
}