part of 'bulk_operation_bloc.dart';

abstract class BulkOperationState extends Equatable {
  const BulkOperationState();

  @override
  List<Object> get props => [];
}

class BulkOperationInitial extends BulkOperationState {}

class BulkOperationLoading extends BulkOperationState {}

class BulkOperationsLoaded extends BulkOperationState {
  final List<BulkOperation> bulkOperations;

  const BulkOperationsLoaded(this.bulkOperations);

  @override
  List<Object> get props => [bulkOperations];
}

class BulkOperationCreated extends BulkOperationState {
  final BulkOperation bulkOperation;

  const BulkOperationCreated(this.bulkOperation);

  @override
  List<Object> get props => [bulkOperation];
}

class BulkOperationExecuted extends BulkOperationState {
  final BulkOperation bulkOperation;

  const BulkOperationExecuted(this.bulkOperation);

  @override
  List<Object> get props => [bulkOperation];
}

class BulkOperationCancelled extends BulkOperationState {
  final BulkOperation bulkOperation;

  const BulkOperationCancelled(this.bulkOperation);

  @override
  List<Object> get props => [bulkOperation];
}

class BulkOperationError extends BulkOperationState {
  final String message;

  const BulkOperationError(this.message);

  @override
  List<Object> get props => [message];
}