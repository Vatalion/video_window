part of 'scheduling_bloc.dart';

abstract class SchedulingEvent extends Equatable {
  const SchedulingEvent();

  @override
  List<Object> get props => [];
}

class LoadScheduledPublishes extends SchedulingEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadScheduledPublishes(this.startDate, this.endDate);

  @override
  List<Object> get props => [startDate, endDate];
}

class CreateScheduledPublish extends SchedulingEvent {
  final ScheduledPublish scheduledPublish;

  const CreateScheduledPublish(this.scheduledPublish);

  @override
  List<Object> get props => [scheduledPublish];
}

class UpdateScheduledPublish extends SchedulingEvent {
  final ScheduledPublish scheduledPublish;

  const UpdateScheduledPublish(this.scheduledPublish);

  @override
  List<Object> get props => [scheduledPublish];
}

class DeleteScheduledPublish extends SchedulingEvent {
  final String scheduledPublishId;

  const DeleteScheduledPublish(this.scheduledPublishId);

  @override
  List<Object> get props => [scheduledPublishId];
}

class MoveScheduledPublish extends SchedulingEvent {
  final ScheduledPublish scheduledPublish;
  final DateTime newScheduledTime;

  const MoveScheduledPublish(this.scheduledPublish, this.newScheduledTime);

  @override
  List<Object> get props => [scheduledPublish, newScheduledTime];
}