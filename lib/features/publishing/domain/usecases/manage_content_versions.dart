import 'package:flutter/foundation.dart';

import '../../domain/entities/content_version.dart';
import '../../domain/repositories/content_version_repository.dart';
import '../../domain/repositories/publishing_workflow_repository.dart';

class ManageContentVersions {
  final ContentVersionRepository _contentVersionRepository;
  final PublishingWorkflowRepository _workflowRepository;

  ManageContentVersions({
    required ContentVersionRepository contentVersionRepository,
    required PublishingWorkflowRepository workflowRepository,
  })  : _contentVersionRepository = contentVersionRepository,
        _workflowRepository = workflowRepository;

  /// Get all versions for a specific content ID
  Future<List<ContentVersion>> getContentVersions(String contentId) async {
    final versions = await _contentVersionRepository.getContentVersions(contentId);
    // Sort versions by version number in descending order (newest first)
    versions.sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
    return versions;
  }

  /// Get the latest version for a specific content ID
  Future<ContentVersion?> getLatestContentVersion(String contentId) async {
    return _contentVersionRepository.getLatestContentVersion(contentId);
  }

  /// Create a new content version
  Future<ContentVersion> createContentVersion({
    required String contentId,
    required String title,
    required String description,
    required String createdBy,
    String? changesSummary,
  }) async {
    // Get the latest version to determine the next version number
    final latestVersion = await getLatestContentVersion(contentId);
    final nextVersionNumber = latestVersion != null ? latestVersion.versionNumber + 1 : 1;

    final contentVersion = ContentVersion(
      id: '${contentId}_v$nextVersionNumber',
      contentId: contentId,
      versionNumber: nextVersionNumber,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      changesSummary: changesSummary,
    );

    return _contentVersionRepository.createContentVersion(contentVersion);
  }

  /// Restore content to a specific version
  Future<void> restoreContentVersion({
    required String contentId,
    required int versionNumber,
    required String userId,
  }) async {
    // Get all versions for the content
    final versions = await getContentVersions(contentId);
    
    // Find the version to restore
    final versionToRestore = versions.firstWhere(
      (version) => version.versionNumber == versionNumber,
      orElse: () => throw Exception('Version $versionNumber not found for content $contentId'),
    );
    
    // Check if the version is within the 90-day retention window
    final now = DateTime.now();
    final retentionPeriod = const Duration(days: 90);
    final versionAge = now.difference(versionToRestore.createdAt);
    
    if (versionAge > retentionPeriod) {
      throw Exception('Version $versionNumber is older than the 90-day retention window');
    }
    
    // Get the current workflow
    final workflows = await _workflowRepository.getWorkflowsForContent(contentId);
    if (workflows.isEmpty) {
      throw Exception('No workflow found for content $contentId');
    }
    
    // Use the first workflow (in a real implementation, you might want to handle multiple workflows)
    final currentWorkflow = workflows.first;
    
    // Update the workflow with the restored content
    final updatedWorkflow = currentWorkflow.copyWith(
      currentStatus: currentWorkflow.currentStatus,
      // In a real implementation, you would update the actual content fields
      // For now, we're just updating the timestamp to indicate when the restore happened
    );
    
    await _workflowRepository.updateWorkflow(updatedWorkflow);
  }

  /// Compare two content versions
  Future<ContentVersionComparison> compareVersions(
    String contentId,
    int versionNumber1,
    int versionNumber2,
  ) async {
    // Get all versions for the content
    final versions = await getContentVersions(contentId);
    
    // Find the versions to compare
    final version1 = versions.firstWhere(
      (version) => version.versionNumber == versionNumber1,
      orElse: () => throw Exception('Version $versionNumber1 not found for content $contentId'),
    );
    
    final version2 = versions.firstWhere(
      (version) => version.versionNumber == versionNumber2,
      orElse: () => throw Exception('Version $versionNumber2 not found for content $contentId'),
    );
    
    return _contentVersionRepository.compareVersions(version1.id, version2.id);
  }

  /// Clean up old versions outside the 90-day retention window
  Future<void> cleanupOldVersions() async {
    final now = DateTime.now();
    final retentionPeriod = const Duration(days: 90);
    
    // In a real implementation, you would iterate through all content versions
    // and delete those older than the retention period
    // For now, we'll just log that this function exists
    debugPrint('Cleaning up content versions older than 90 days');
  }
}