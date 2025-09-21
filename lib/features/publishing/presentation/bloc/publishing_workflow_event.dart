part of 'publishing_workflow_bloc.dart';

abstract class PublishingWorkflowEvent extends Equatable {
  const PublishingWorkflowEvent();

  @override
  List<Object> get props => [];
}

class LoadWorkflow extends PublishingWorkflowEvent {
  final String workflowId;

  const LoadWorkflow(this.workflowId);

  @override
  List<Object> get props => [workflowId];
}

class CreateWorkflow extends PublishingWorkflowEvent {
  final PublishingWorkflow workflow;

  const CreateWorkflow(this.workflow);

  @override
  List<Object> get props => [workflow];
}

class UpdateWorkflowStatus extends PublishingWorkflowEvent {
  final String workflowId;
  final PublishingStatus newStatus;
  final String userId;
  final String notes;

  const UpdateWorkflowStatus({
    required this.workflowId,
    required this.newStatus,
    required this.userId,
    this.notes = '',
  });

  @override
  List<Object> get props => [workflowId, newStatus, userId];
}

class DeleteWorkflow extends PublishingWorkflowEvent {
  final String workflowId;

  const DeleteWorkflow(this.workflowId);

  @override
  List<Object> get props => [workflowId];
}

class LoadWorkflowsByStatus extends PublishingWorkflowEvent {
  final PublishingStatus status;

  const LoadWorkflowsByStatus(this.status);

  @override
  List<Object> get props => [status];
}

class LoadProcessingStatus extends PublishingWorkflowEvent {
  final String workflowId;

  const LoadProcessingStatus(this.workflowId);

  @override
  List<Object> get props => [workflowId];
}

class WorkflowUpdated extends PublishingWorkflowEvent {
  final PublishingWorkflow workflow;

  const WorkflowUpdated(this.workflow);

  @override
  List<Object> get props => [workflow];
}