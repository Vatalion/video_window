part of 'bulk_operation_bloc.dart';

abstract class BulkOperationEvent extends Equatable {
  const BulkOperationEvent();

  @override
  List<Object> get props => [];
}

class LoadBulkOperations extends BulkOperationEvent {
  final String userId;

  const LoadBulkOperations(this.userId);

  @override
  List<Object> get props => [userId];
}

class CreateBulkOperation extends BulkOperationEvent {
  final BulkOperation bulkOperation;

  const CreateBulkOperation(this.bulkOperation);

  @override
  List<Object> get props => [bulkOperation];
}

class ExecuteBulkOperation extends BulkOperationEvent {
  final String bulkOperationId;

  const ExecuteBulkOperation(this.bulkOperationId);

  @override
  List<Object> get props => [bulkOperationId];
}

class CancelBulkOperation extends BulkOperationEvent {
  final String bulkOperationId;

  const CancelBulkOperation(this.bulkOperationId);

  @override
  List<Object> get props => [bulkOperationId];
}