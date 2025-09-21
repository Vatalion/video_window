part of 'publishing_workflow_bloc.dart';

abstract class PublishingWorkflowState extends Equatable {
  const PublishingWorkflowState();

  @override
  List<Object> get props => [];
}

class PublishingWorkflowInitial extends PublishingWorkflowState {}

class PublishingWorkflowLoading extends PublishingWorkflowState {}

class PublishingWorkflowLoaded extends PublishingWorkflowState {
  final PublishingWorkflow workflow;

  const PublishingWorkflowLoaded(this.workflow);

  @override
  List<Object> get props => [workflow];
}

class PublishingWorkflowsLoaded extends PublishingWorkflowState {
  final List<PublishingWorkflow> workflows;

  const PublishingWorkflowsLoaded(this.workflows);

  @override
  List<Object> get props => [workflows];
}

class PublishingWorkflowProcessingStatus extends PublishingWorkflowState {
  final ProcessingStatus status;

  const PublishingWorkflowProcessingStatus(this.status);

  @override
  List<Object> get props => [status];
}

class PublishingWorkflowDeleted extends PublishingWorkflowState {}

class PublishingWorkflowError extends PublishingWorkflowState {
  final String message;

  const PublishingWorkflowError(this.message);

  @override
  List<Object> get props => [message];
}

class PublishingWorkflowUpdated extends PublishingWorkflowState {
  final PublishingWorkflow workflow;

  const PublishingWorkflowUpdated(this.workflow);

  @override
  List<Object> get props => [workflow];
}