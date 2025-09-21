import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/publishing_workflow.dart';
import '../../domain/enums/publishing_status.dart';
import '../../domain/repositories/publishing_workflow_repository.dart';
import '../../data/services/content_processing_service.dart';

part 'publishing_workflow_event.dart';
part 'publishing_workflow_state.dart';

class PublishingWorkflowBloc extends Bloc<PublishingWorkflowEvent, PublishingWorkflowState> {
  final PublishingWorkflowRepository _workflowRepository;
  final ContentProcessingService _processingService;

  PublishingWorkflowBloc({
    required PublishingWorkflowRepository workflowRepository,
    required ContentProcessingService processingService,
  })  : _workflowRepository = workflowRepository,
        _processingService = processingService,
        super(PublishingWorkflowInitial()) {
    on<LoadWorkflow>(_onLoadWorkflow);
    on<CreateWorkflow>(_onCreateWorkflow);
    on<UpdateWorkflowStatus>(_onUpdateWorkflowStatus);
    on<DeleteWorkflow>(_onDeleteWorkflow);
    on<LoadWorkflowsByStatus>(_onLoadWorkflowsByStatus);
    on<LoadProcessingStatus>(_onLoadProcessingStatus);
    on<WorkflowUpdated>(_onWorkflowUpdated);
  }

  Future<void> _onLoadWorkflow(
    LoadWorkflow event,
    Emitter<PublishingWorkflowState> emit,
  ) async {
    emit(PublishingWorkflowLoading());
    try {
      final workflow = await _workflowRepository.getWorkflow(event.workflowId);
      if (workflow != null) {
        emit(PublishingWorkflowLoaded(workflow));
      } else {
        emit(PublishingWorkflowError('Workflow not found'));
      }
    } catch (e) {
      emit(PublishingWorkflowError(e.toString()));
    }
  }

  Future<void> _onCreateWorkflow(
    CreateWorkflow event,
    Emitter<PublishingWorkflowState> emit,
  ) async {
    emit(PublishingWorkflowLoading());
    try {
      final workflow = await _workflowRepository.createWorkflow(event.workflow);
      emit(PublishingWorkflowLoaded(workflow));
    } catch (e) {
      emit(PublishingWorkflowError(e.toString()));
    }
  }

  Future<void> _onUpdateWorkflowStatus(
    UpdateWorkflowStatus event,
    Emitter<PublishingWorkflowState> emit,
  ) async {
    emit(PublishingWorkflowLoading());
    try {
      final workflow = await _workflowRepository.transitionStatus(
        event.workflowId,
        event.newStatus,
        event.userId,
        notes: event.notes,
      );
      emit(PublishingWorkflowLoaded(workflow));
    } catch (e) {
      emit(PublishingWorkflowError(e.toString()));
    }
  }

  Future<void> _onDeleteWorkflow(
    DeleteWorkflow event,
    Emitter<PublishingWorkflowState> emit,
  ) async {
    emit(PublishingWorkflowLoading());
    try {
      final success = await _workflowRepository.deleteWorkflow(event.workflowId);
      if (success) {
        emit(PublishingWorkflowDeleted());
      } else {
        emit(PublishingWorkflowError('Failed to delete workflow'));
      }
    } catch (e) {
      emit(PublishingWorkflowError(e.toString()));
    }
  }

  Future<void> _onLoadWorkflowsByStatus(
    LoadWorkflowsByStatus event,
    Emitter<PublishingWorkflowState> emit,
  ) async {
    emit(PublishingWorkflowLoading());
    try {
      final workflows = await _workflowRepository.getWorkflowsByStatus(event.status);
      emit(PublishingWorkflowsLoaded(workflows));
    } catch (e) {
      emit(PublishingWorkflowError(e.toString()));
    }
  }

  Future<void> _onLoadProcessingStatus(
    LoadProcessingStatus event,
    Emitter<PublishingWorkflowState> emit,
  ) async {
    try {
      final processingStatus = _processingService.getProcessingStatus(event.workflowId);
      if (processingStatus != null) {
        emit(PublishingWorkflowProcessingStatus(processingStatus));
      }
    } catch (e) {
      emit(PublishingWorkflowError(e.toString()));
    }
  }

  Future<void> _onWorkflowUpdated(
    WorkflowUpdated event,
    Emitter<PublishingWorkflowState> emit,
  ) async {
    emit(PublishingWorkflowUpdated(event.workflow));
  }
}