import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/publishing/presentation/bloc/publishing_workflow_bloc.dart';
import 'package:video_window/features/publishing/domain/repositories/publishing_workflow_repository.dart';
import 'package:video_window/features/publishing/data/services/content_processing_service.dart';
import 'package:video_window/features/publishing/domain/entities/publishing_workflow.dart';
import 'package:video_window/features/publishing/domain/enums/publishing_status.dart';

class MockPublishingWorkflowRepository extends Mock
    implements PublishingWorkflowRepository {}

class MockContentProcessingService extends Mock
    implements ContentProcessingService {}

void main() {
  group('PublishingWorkflowBloc', () {
    late PublishingWorkflowRepository workflowRepository;
    late ContentProcessingService processingService;
    late PublishingWorkflowBloc bloc;

    setUp(() {
      workflowRepository = MockPublishingWorkflowRepository();
      processingService = MockContentProcessingService();
      bloc = PublishingWorkflowBloc(
        workflowRepository: workflowRepository,
        processingService: processingService,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is PublishingWorkflowInitial', () {
      expect(bloc.state, equals(PublishingWorkflowInitial()));
    });

    blocTest<PublishingWorkflowBloc, PublishingWorkflowState>(
      'emits [PublishingWorkflowLoading, PublishingWorkflowLoaded] when LoadWorkflow is added',
      build: () {
        when(() => workflowRepository.getWorkflow('workflow1'))
            .thenAnswer((_) async => PublishingWorkflow(
                  id: 'workflow1',
                  contentId: 'content1',
                  currentStatus: PublishingStatus.draft,
                  statusHistory: [],
                ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadWorkflow('workflow1')),
      expect: () => [
        PublishingWorkflowLoading(),
        const PublishingWorkflowLoaded(PublishingWorkflow(
          id: 'workflow1',
          contentId: 'content1',
          currentStatus: PublishingStatus.draft,
          statusHistory: [],
        )),
      ],
    );

    blocTest<PublishingWorkflowBloc, PublishingWorkflowState>(
      'emits [PublishingWorkflowLoading, PublishingWorkflowsLoaded] when LoadWorkflowsByStatus is added',
      build: () {
        when(() => workflowRepository.getWorkflowsByStatus(PublishingStatus.draft))
            .thenAnswer((_) async => [
                  PublishingWorkflow(
                    id: 'workflow1',
                    contentId: 'content1',
                    currentStatus: PublishingStatus.draft,
                    statusHistory: [],
                  ),
                  PublishingWorkflow(
                    id: 'workflow2',
                    contentId: 'content2',
                    currentStatus: PublishingStatus.draft,
                    statusHistory: [],
                  ),
                ]);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadWorkflowsByStatus(PublishingStatus.draft)),
      expect: () => [
        PublishingWorkflowLoading(),
        PublishingWorkflowsLoaded([
          PublishingWorkflow(
            id: 'workflow1',
            contentId: 'content1',
            currentStatus: PublishingStatus.draft,
            statusHistory: [],
          ),
          PublishingWorkflow(
            id: 'workflow2',
            contentId: 'content2',
            currentStatus: PublishingStatus.draft,
            statusHistory: [],
          ),
        ]),
      ],
    );

    blocTest<PublishingWorkflowBloc, PublishingWorkflowState>(
      'emits [PublishingWorkflowLoading, PublishingWorkflowError] when LoadWorkflow fails',
      build: () {
        when(() => workflowRepository.getWorkflow('workflow1'))
            .thenThrow(Exception('Workflow not found'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadWorkflow('workflow1')),
      expect: () => [
        PublishingWorkflowLoading(),
        const PublishingWorkflowError('Exception: Workflow not found'),
      ],
    );
  });
}