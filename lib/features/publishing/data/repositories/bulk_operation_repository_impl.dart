import 'package:flutter/foundation.dart';

import '../../domain/entities/bulk_operation.dart';
import '../../domain/repositories/bulk_operation_repository.dart';
import '../services/bulk_operation_service.dart';

class BulkOperationRepositoryImpl implements BulkOperationRepository {
  final BulkOperationService _bulkOperationService;

  BulkOperationRepositoryImpl({required BulkOperationService bulkOperationService})
      : _bulkOperationService = bulkOperationService;

  @override
  Future<BulkOperation?> getBulkOperation(String id) async {
    return _bulkOperationService.getBulkOperation(id);
  }

  @override
  Future<BulkOperation> createBulkOperation(BulkOperation bulkOperation) async {
    return _bulkOperationService.createBulkOperation(bulkOperation);
  }

  @override
  Future<BulkOperation> updateBulkOperation(BulkOperation bulkOperation) async {
    return _bulkOperationService.updateBulkOperation(bulkOperation);
  }

  @override
  Future<bool> deleteBulkOperation(String id) async {
    return _bulkOperationService.deleteBulkOperation(id);
  }

  @override
  Future<List<BulkOperation>> getUserBulkOperations(String userId) async {
    return _bulkOperationService.getUserBulkOperations(userId);
  }

  @override
  Future<BulkOperation> executeBulkOperation(String bulkOperationId) async {
    return _bulkOperationService.executeBulkOperation(bulkOperationId);
  }
}