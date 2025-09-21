part of 'scheduling_bloc.dart';

abstract class SchedulingState extends Equatable {
  const SchedulingState();

  @override
  List<Object> get props => [];
}

class SchedulingInitial extends SchedulingState {}

class SchedulingLoading extends SchedulingState {}

class SchedulingLoaded extends SchedulingState {
  final List<ScheduledPublish> scheduledPublishes;

  const SchedulingLoaded(this.scheduledPublishes);

  @override
  List<Object> get props => [scheduledPublishes];
}

class SchedulingConflictDetected extends SchedulingState {
  final List<ScheduledPublish> conflicts;

  const SchedulingConflictDetected(this.conflicts);

  @override
  List<Object> get props => [conflicts];
}

class SchedulingError extends SchedulingState {
  final String message;

  const SchedulingError(this.message);

  @override
  List<Object> get props => [message];
}