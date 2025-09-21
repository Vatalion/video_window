import 'package:equatable/equatable.dart';

import '../enums/publishing_status.dart';

class StatusChange extends Equatable {
  const StatusChange({
    required this.fromStatus,
    required this.toStatus,
    required this.timestamp,
    required this.userId,
    this.notes = '',
  });

  final PublishingStatus fromStatus;
  final PublishingStatus toStatus;
  final DateTime timestamp;
  final String userId;
  final String notes;

  StatusChange copyWith({
    PublishingStatus? fromStatus,
    PublishingStatus? toStatus,
    DateTime? timestamp,
    String? userId,
    String? notes,
  }) {
    return StatusChange(
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        fromStatus,
        toStatus,
        timestamp,
        userId,
        notes,
      ];
}