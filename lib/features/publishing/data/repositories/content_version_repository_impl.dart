import 'package:flutter/foundation.dart';

import '../../domain/entities/content_version.dart';
import '../../domain/repositories/content_version_repository.dart';
import '../services/content_version_service.dart';

class ContentVersionRepositoryImpl implements ContentVersionRepository {
  final ContentVersionService _contentVersionService;

  ContentVersionRepositoryImpl({
    required ContentVersionService contentVersionService,
  }) : _contentVersionService = contentVersionService;

  @override
  Future<ContentVersion?> getContentVersion(String id) async {
    return _contentVersionService.getContentVersion(id);
  }

  @override
  Future<List<ContentVersion>> getContentVersions(String contentId) async {
    return _contentVersionService.getContentVersions(contentId);
  }

  @override
  Future<ContentVersion?> getLatestContentVersion(String contentId) async {
    return _contentVersionService.getLatestContentVersion(contentId);
  }

  @override
  Future<ContentVersion> createContentVersion(ContentVersion contentVersion) async {
    return _contentVersionService.createContentVersion(contentVersion);
  }

  @override
  Future<ContentVersion> updateContentVersion(ContentVersion contentVersion) async {
    return _contentVersionService.updateContentVersion(contentVersion);
  }

  @override
  Future<bool> deleteContentVersion(String id) async {
    return _contentVersionService.deleteContentVersion(id);
  }

  @override
  Future<ContentVersionComparison> compareVersions(
    String versionId1,
    String versionId2,
  ) async {
    return _contentVersionService.compareVersions(versionId1, versionId2);
  }
}