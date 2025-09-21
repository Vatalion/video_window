import 'package:equatable/equatable.dart';
import '../enums/recurrence_type.dart';

class ScheduledPublish extends Equatable {
  final String id;
  final String workflowId;
  final DateTime scheduledTime;
  final String timezone;
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;

  const ScheduledPublish({
    required this.id,
    required this.workflowId,
    required this.scheduledTime,
    required this.timezone,
    this.isRecurring = false,
    this.recurrencePattern,
  });

  ScheduledPublish copyWith({
    String? id,
    String? workflowId,
    DateTime? scheduledTime,
    String? timezone,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
  }) {
    return ScheduledPublish(
      id: id ?? this.id,
      workflowId: workflowId ?? this.workflowId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      timezone: timezone ?? this.timezone,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workflowId,
        scheduledTime,
        timezone,
        isRecurring,
        recurrencePattern,
      ];
}

class RecurrencePattern extends Equatable {
  final RecurrenceType type;
  final int interval;
  final List<int>? daysOfWeek;
  final DateTime? endDate;

  const RecurrencePattern({
    required this.type,
    required this.interval,
    this.daysOfWeek,
    this.endDate,
  });

  RecurrencePattern copyWith({
    RecurrenceType? type,
    int? interval,
    List<int>? daysOfWeek,
    DateTime? endDate,
  }) {
    return RecurrencePattern(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        type,
        interval,
        daysOfWeek,
        endDate,
      ];
}