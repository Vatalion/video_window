import 'package:equatable/equatable.dart';

import 'publishing_workflow.dart';

class BulkOperation extends Equatable {
  final String id;
  final String userId;
  final List<String> workflowIds;
  final BulkOperationType operationType;
  final BulkOperationStatus status;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<BulkOperationItem> items;

  const BulkOperation({
    required this.id,
    required this.userId,
    required this.workflowIds,
    required this.operationType,
    required this.status,
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    required this.createdAt,
    this.completedAt,
    required this.items,
  });

  BulkOperation copyWith({
    String? id,
    String? userId,
    List<String>? workflowIds,
    BulkOperationType? operationType,
    BulkOperationStatus? status,
    int? totalItems,
    int? processedItems,
    int? failedItems,
    DateTime? createdAt,
    DateTime? completedAt,
    List<BulkOperationItem>? items,
  }) {
    return BulkOperation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workflowIds: workflowIds ?? this.workflowIds,
      operationType: operationType ?? this.operationType,
      status: status ?? this.status,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      failedItems: failedItems ?? this.failedItems,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      items: items ?? this.items,
    );
  }

  double get progress => totalItems > 0 ? processedItems / totalItems : 0.0;

  @override
  List<Object?> get props => [
        id,
        userId,
        workflowIds,
        operationType,
        status,
        totalItems,
        processedItems,
        failedItems,
        createdAt,
        completedAt,
        items,
      ];
}

class BulkOperationItem extends Equatable {
  final String workflowId;
  final BulkOperationStatus status;
  final String? errorMessage;
  final DateTime processedAt;

  const BulkOperationItem({
    required this.workflowId,
    required this.status,
    this.errorMessage,
    required this.processedAt,
  });

  BulkOperationItem copyWith({
    String? workflowId,
    BulkOperationStatus? status,
    String? errorMessage,
    DateTime? processedAt,
  }) {
    return BulkOperationItem(
      workflowId: workflowId ?? this.workflowId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  List<Object?> get props => [
        workflowId,
        status,
        errorMessage,
        processedAt,
      ];
}

enum BulkOperationType {
  publish,
  schedule,
  archive,
  delete,
}

enum BulkOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}