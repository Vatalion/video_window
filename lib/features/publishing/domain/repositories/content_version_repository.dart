import 'package:flutter/foundation.dart';

import '../entities/content_version.dart';

abstract class ContentVersionRepository {
  /// Get a content version by ID
  Future<ContentVersion?> getContentVersion(String id);

  /// Get all versions for a specific content ID
  Future<List<ContentVersion>> getContentVersions(String contentId);

  /// Get the latest version for a specific content ID
  Future<ContentVersion?> getLatestContentVersion(String contentId);

  /// Create a new content version
  Future<ContentVersion> createContentVersion(ContentVersion contentVersion);

  /// Update an existing content version
  Future<ContentVersion> updateContentVersion(ContentVersion contentVersion);

  /// Delete a content version
  Future<bool> deleteContentVersion(String id);

  /// Compare two content versions
  Future<ContentVersionComparison> compareVersions(
    String versionId1,
    String versionId2,
  );
}

class ContentVersionComparison {
  final ContentVersion version1;
  final ContentVersion version2;
  final List<String> differences;

  ContentVersionComparison({
    required this.version1,
    required this.version2,
    required this.differences,
  });
}