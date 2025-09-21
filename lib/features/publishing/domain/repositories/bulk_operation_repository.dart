import 'package:flutter/foundation.dart';

import '../entities/bulk_operation.dart';

abstract class BulkOperationRepository {
  /// Get a bulk operation by ID
  Future<BulkOperation?> getBulkOperation(String id);

  /// Create a new bulk operation
  Future<BulkOperation> createBulkOperation(BulkOperation bulkOperation);

  /// Update an existing bulk operation
  Future<BulkOperation> updateBulkOperation(BulkOperation bulkOperation);

  /// Delete a bulk operation
  Future<bool> deleteBulkOperation(String id);

  /// Get all bulk operations for a user
  Future<List<BulkOperation>> getUserBulkOperations(String userId);

  /// Execute a bulk operation
  Future<BulkOperation> executeBulkOperation(String bulkOperationId);
}