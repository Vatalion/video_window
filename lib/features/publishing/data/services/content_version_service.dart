import 'package:flutter/foundation.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

import '../../domain/entities/content_version.dart';
import '../../domain/repositories/content_version_repository.dart';

class ContentVersionService implements ContentVersionRepository {
  // In-memory storage for content versions
  final Map<String, ContentVersion> _contentVersions = {};
  
  // In-memory storage for content version mappings
  final Map<String, List<String>> _contentVersionMappings = {};

  @override
  Future<ContentVersion?> getContentVersion(String id) async {
    return _contentVersions[id];
  }

  @override
  Future<List<ContentVersion>> getContentVersions(String contentId) async {
    final versionIds = _contentVersionMappings[contentId] ?? [];
    return versionIds.map((id) => _contentVersions[id]!).toList();
  }

  @override
  Future<ContentVersion?> getLatestContentVersion(String contentId) async {
    final versions = await getContentVersions(contentId);
    if (versions.isEmpty) return null;
    
    // Sort versions by version number and return the latest
    versions.sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
    return versions.first;
  }

  @override
  Future<ContentVersion> createContentVersion(ContentVersion contentVersion) async {
    _contentVersions[contentVersion.id] = contentVersion;
    
    // Add to content version mappings
    if (_contentVersionMappings.containsKey(contentVersion.contentId)) {
      _contentVersionMappings[contentVersion.contentId]!.add(contentVersion.id);
    } else {
      _contentVersionMappings[contentVersion.contentId] = [contentVersion.id];
    }
    
    return contentVersion;
  }

  @override
  Future<ContentVersion> updateContentVersion(ContentVersion contentVersion) async {
    _contentVersions[contentVersion.id] = contentVersion;
    return contentVersion;
  }

  @override
  Future<bool> deleteContentVersion(String id) async {
    if (_contentVersions.containsKey(id)) {
      final contentVersion = _contentVersions[id]!;
      _contentVersions.remove(id);
      
      // Remove from content version mappings
      if (_contentVersionMappings.containsKey(contentVersion.contentId)) {
        _contentVersionMappings[contentVersion.contentId]!.remove(id);
        if (_contentVersionMappings[contentVersion.contentId]!.isEmpty) {
          _contentVersionMappings.remove(contentVersion.contentId);
        }
      }
      
      return true;
    }
    return false;
  }

  @override
  Future<ContentVersionComparison> compareVersions(
    String versionId1,
    String versionId2,
  ) async {
    final version1 = _contentVersions[versionId1];
    final version2 = _contentVersions[versionId2];
    
    if (version1 == null || version2 == null) {
      throw Exception('One or both versions not found');
    }
    
    // Use diff_match_patch to compare the content
    final dmp = DiffMatchPatch();
    final diffs = dmp.diffMain(
      '${version1.title}\n${version1.description}', 
      '${version2.title}\n${version2.description}'
    );
    dmp.diffCleanupSemantic(diffs);
    
    // Convert diffs to readable format
    final differences = diffs.map((diff) => diff.toString()).toList();
    
    return ContentVersionComparison(
      version1: version1,
      version2: version2,
      differences: differences,
    );
  }
}