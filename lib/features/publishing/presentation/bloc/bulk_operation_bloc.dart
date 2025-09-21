import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/bulk_operation.dart';
import '../../domain/repositories/bulk_operation_repository.dart';

part 'bulk_operation_event.dart';
part 'bulk_operation_state.dart';

class BulkOperationBloc extends Bloc<BulkOperationEvent, BulkOperationState> {
  final BulkOperationRepository _bulkOperationRepository;

  BulkOperationBloc({required BulkOperationRepository bulkOperationRepository})
      : _bulkOperationRepository = bulkOperationRepository,
        super(BulkOperationInitial()) {
    on<LoadBulkOperations>(_onLoadBulkOperations);
    on<CreateBulkOperation>(_onCreateBulkOperation);
    on<ExecuteBulkOperation>(_onExecuteBulkOperation);
    on<CancelBulkOperation>(_onCancelBulkOperation);
  }

  Future<void> _onLoadBulkOperations(
    LoadBulkOperations event,
    Emitter<BulkOperationState> emit,
  ) async {
    emit(BulkOperationLoading());
    try {
      final bulkOperations = await _bulkOperationRepository.getUserBulkOperations(event.userId);
      emit(BulkOperationsLoaded(bulkOperations));
    } catch (e) {
      emit(BulkOperationError(e.toString()));
    }
  }

  Future<void> _onCreateBulkOperation(
    CreateBulkOperation event,
    Emitter<BulkOperationState> emit,
  ) async {
    emit(BulkOperationLoading());
    try {
      final bulkOperation = await _bulkOperationRepository.createBulkOperation(event.bulkOperation);
      emit(BulkOperationCreated(bulkOperation));
      
      // Also load all bulk operations to update the list
      final bulkOperations = await _bulkOperationRepository.getUserBulkOperations(event.bulkOperation.userId);
      emit(BulkOperationsLoaded(bulkOperations));
    } catch (e) {
      emit(BulkOperationError(e.toString()));
    }
  }

  Future<void> _onExecuteBulkOperation(
    ExecuteBulkOperation event,
    Emitter<BulkOperationState> emit,
  ) async {
    emit(BulkOperationLoading());
    try {
      final bulkOperation = await _bulkOperationRepository.executeBulkOperation(event.bulkOperationId);
      emit(BulkOperationExecuted(bulkOperation));
      
      // Also load all bulk operations to update the list
      final bulkOperations = await _bulkOperationRepository.getUserBulkOperations(bulkOperation.userId);
      emit(BulkOperationsLoaded(bulkOperations));
    } catch (e) {
      emit(BulkOperationError(e.toString()));
    }
  }

  Future<void> _onCancelBulkOperation(
    CancelBulkOperation event,
    Emitter<BulkOperationState> emit,
  ) async {
    emit(BulkOperationLoading());
    try {
      // In a real implementation, this would cancel the bulk operation
      // For now, we'll just update the status
      final bulkOperation = await _bulkOperationRepository.getBulkOperation(event.bulkOperationId);
      if (bulkOperation != null) {
        final cancelledOperation = bulkOperation.copyWith(status: BulkOperationStatus.cancelled);
        await _bulkOperationRepository.updateBulkOperation(cancelledOperation);
        
        // Also load all bulk operations to update the list
        final bulkOperations = await _bulkOperationRepository.getUserBulkOperations(cancelledOperation.userId);
        emit(BulkOperationsLoaded(bulkOperations));
      } else {
        emit(const BulkOperationError('Bulk operation not found'));
      }
    } catch (e) {
      emit(BulkOperationError(e.toString()));
    }
  }
}