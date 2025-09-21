import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/scheduled_publish.dart';
import '../../domain/repositories/scheduled_publish_repository.dart';

part 'scheduling_event.dart';
part 'scheduling_state.dart';

class SchedulingBloc extends Bloc<SchedulingEvent, SchedulingState> {
  final ScheduledPublishRepository _scheduledPublishRepository;

  SchedulingBloc({required ScheduledPublishRepository scheduledPublishRepository})
      : _scheduledPublishRepository = scheduledPublishRepository,
        super(SchedulingInitial()) {
    on<LoadScheduledPublishes>(_onLoadScheduledPublishes);
    on<CreateScheduledPublish>(_onCreateScheduledPublish);
    on<UpdateScheduledPublish>(_onUpdateScheduledPublish);
    on<DeleteScheduledPublish>(_onDeleteScheduledPublish);
    on<MoveScheduledPublish>(_onMoveScheduledPublish);
  }

  Future<void> _onLoadScheduledPublishes(
    LoadScheduledPublishes event,
    Emitter<SchedulingState> emit,
  ) async {
    emit(SchedulingLoading());
    try {
      final scheduledPublishes = await _scheduledPublishRepository.getScheduledPublishesByDateRange(
        event.startDate,
        event.endDate,
      );
      emit(SchedulingLoaded(scheduledPublishes));
    } catch (e) {
      emit(SchedulingError(e.toString()));
    }
  }

  Future<void> _onCreateScheduledPublish(
    CreateScheduledPublish event,
    Emitter<SchedulingState> emit,
  ) async {
    emit(SchedulingLoading());
    
    // Check for conflicts
    try {
      final conflicts = await _checkForConflicts(event.scheduledPublish);
      if (conflicts.isNotEmpty) {
        emit(SchedulingConflictDetected(conflicts));
        return;
      }
    } catch (e) {
      emit(SchedulingError('Failed to check for conflicts: ${e.toString()}'));
      return;
    }
    
    try {
      final scheduledPublish = await _scheduledPublishRepository.createScheduledPublish(
        event.scheduledPublish,
      );
      
      // Reload the current scheduled publishes
      if (state is SchedulingLoaded) {
        final currentScheduledPublishes = (state as SchedulingLoaded).scheduledPublishes;
        emit(SchedulingLoaded([...currentScheduledPublishes, scheduledPublish]));
      } else {
        emit(SchedulingLoaded([scheduledPublish]));
      }
    } catch (e) {
      emit(SchedulingError(e.toString()));
    }
  }

  Future<void> _onUpdateScheduledPublish(
    UpdateScheduledPublish event,
    Emitter<SchedulingState> emit,
  ) async {
    emit(SchedulingLoading());
    
    // Check for conflicts (excluding the current scheduled publish being updated)
    try {
      final conflicts = await _checkForConflicts(event.scheduledPublish, excludeId: event.scheduledPublish.id);
      if (conflicts.isNotEmpty) {
        emit(SchedulingConflictDetected(conflicts));
        return;
      }
    } catch (e) {
      emit(SchedulingError('Failed to check for conflicts: ${e.toString()}'));
      return;
    }
    
    try {
      final scheduledPublish = await _scheduledPublishRepository.updateScheduledPublish(
        event.scheduledPublish,
      );
      
      // Update the current scheduled publishes
      if (state is SchedulingLoaded) {
        final currentScheduledPublishes = (state as SchedulingLoaded).scheduledPublishes;
        final updatedScheduledPublishes = currentScheduledPublishes.map((item) {
          return item.id == scheduledPublish.id ? scheduledPublish : item;
        }).toList();
        emit(SchedulingLoaded(updatedScheduledPublishes));
      } else {
        emit(SchedulingLoaded([scheduledPublish]));
      }
    } catch (e) {
      emit(SchedulingError(e.toString()));
    }
  }

  Future<void> _onDeleteScheduledPublish(
    DeleteScheduledPublish event,
    Emitter<SchedulingState> emit,
  ) async {
    emit(SchedulingLoading());
    try {
      final success = await _scheduledPublishRepository.deleteScheduledPublish(
        event.scheduledPublishId,
      );
      
      if (success) {
        // Remove from the current scheduled publishes
        if (state is SchedulingLoaded) {
          final currentScheduledPublishes = (state as SchedulingLoaded).scheduledPublishes;
          final updatedScheduledPublishes = currentScheduledPublishes
              .where((item) => item.id != event.scheduledPublishId)
              .toList();
          emit(SchedulingLoaded(updatedScheduledPublishes));
        }
      } else {
        emit(const SchedulingError('Failed to delete scheduled publish'));
      }
    } catch (e) {
      emit(SchedulingError(e.toString()));
    }
  }

  Future<void> _onMoveScheduledPublish(
    MoveScheduledPublish event,
    Emitter<SchedulingState> emit,
  ) async {
    emit(SchedulingLoading());
    
    // Check for conflicts
    try {
      final scheduledPublish = await _scheduledPublishRepository.getScheduledPublish(event.scheduledPublish.id);
      if (scheduledPublish == null) {
        emit(const SchedulingError('Scheduled publish not found'));
        return;
      }
      
      final updatedScheduledPublish = scheduledPublish.copyWith(
        scheduledTime: event.newScheduledTime,
      );
      
      final conflicts = await _checkForConflicts(updatedScheduledPublish, excludeId: event.scheduledPublish.id);
      if (conflicts.isNotEmpty) {
        emit(SchedulingConflictDetected(conflicts));
        return;
      }
      
      // Update the scheduled publish with the new time
      final result = await _scheduledPublishRepository.updateScheduledPublish(updatedScheduledPublish);
      
      // Update the current scheduled publishes
      if (state is SchedulingLoaded) {
        final currentScheduledPublishes = (state as SchedulingLoaded).scheduledPublishes;
        final updatedScheduledPublishes = currentScheduledPublishes.map((item) {
          return item.id == result.id ? result : item;
        }).toList();
        emit(SchedulingLoaded(updatedScheduledPublishes));
      } else {
        emit(SchedulingLoaded([result]));
      }
    } catch (e) {
      emit(SchedulingError(e.toString()));
    }
  }
  
  /// Check for scheduling conflicts
  Future<List<ScheduledPublish>> _checkForConflicts(
    ScheduledPublish newScheduledPublish, {
    String? excludeId,
  }) async {
    // Get all scheduled publishes for the same workflow within a 24-hour window
    final startDate = newScheduledPublish.scheduledTime.subtract(const Duration(hours: 12));
    final endDate = newScheduledPublish.scheduledTime.add(const Duration(hours: 12));
    
    final existingScheduledPublishes = await _scheduledPublishRepository.getScheduledPublishesByDateRange(
      startDate,
      endDate,
    );
    
    // Remove the scheduled publish being updated from conflict check
    final filteredScheduledPublishes = excludeId != null
        ? existingScheduledPublishes.where((item) => item.id != excludeId).toList()
        : existingScheduledPublishes;
    
    // Check for time overlap conflicts
    final conflicts = <ScheduledPublish>[];
    for (final existing in filteredScheduledPublishes) {
      // Check if the new scheduled publish is for the same workflow
      if (existing.workflowId == newScheduledPublish.workflowId) {
        // For simplicity, we'll check if the scheduled times overlap within a 1-hour window
        // In a real implementation, this would be more sophisticated conflict detection
        final existingEndTime = existing.scheduledTime.add(const Duration(hours: 1));
        final newEndTime = newScheduledPublish.scheduledTime.add(const Duration(hours: 1));
        
        if ((newScheduledPublish.scheduledTime.isAfter(existing.scheduledTime) && 
             newScheduledPublish.scheduledTime.isBefore(existingEndTime)) ||
            (newEndTime.isAfter(existing.scheduledTime) && 
             newEndTime.isBefore(existingEndTime)) ||
            (newScheduledPublish.scheduledTime.isAtSameMomentAs(existing.scheduledTime))) {
          conflicts.add(existing);
        }
      }
    }
    
    return conflicts;
  }
}