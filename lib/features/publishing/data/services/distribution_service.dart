import 'package:flutter/foundation.dart';

import '../../domain/entities/distribution_channel.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../content_processing_service.dart';
import '../publishing_workflow_service.dart';

class DistributionService implements DistributionRepository {
  final PublishingWorkflowService _workflowService;
  final ContentProcessingService _contentProcessingService;
  
  // In-memory storage for distribution channels
  final Map<String, DistributionChannel> _distributionChannels = {};
  
  // In-memory storage for distribution settings
  final Map<String, List<DistributionSettings>> _contentDistributionSettings = {};

  DistributionService({
    required PublishingWorkflowService workflowService,
    required ContentProcessingService contentProcessingService,
  })  : _workflowService = workflowService,
        _contentProcessingService = contentProcessingService;

  @override
  Future<DistributionChannel?> getDistributionChannel(String id) async {
    return _distributionChannels[id];
  }

  @override
  Future<List<DistributionChannel>> getAllDistributionChannels() async {
    return _distributionChannels.values.toList();
  }

  @override
  Future<List<DistributionChannel>> getActiveDistributionChannels() async {
    return _distributionChannels.values
        .where((channel) => channel.isActive)
        .toList();
  }

  @override
  Future<DistributionChannel> createDistributionChannel(DistributionChannel channel) async {
    _distributionChannels[channel.id] = channel;
    return channel;
  }

  @override
  Future<DistributionChannel> updateDistributionChannel(DistributionChannel channel) async {
    _distributionChannels[channel.id] = channel;
    return channel;
  }

  @override
  Future<bool> deleteDistributionChannel(String id) async {
    return _distributionChannels.remove(id) != null;
  }

  @override
  Future<List<DistributionSettings>> getDistributionSettingsForContent(String contentId) async {
    return _contentDistributionSettings[contentId] ?? [];
  }

  @override
  Future<DistributionSettings> updateDistributionSettings(DistributionSettings settings) async {
    final contentId = settings.contentId;
    
    if (_contentDistributionSettings.containsKey(contentId)) {
      final existingSettings = _contentDistributionSettings[contentId]!;
      final index = existingSettings.indexWhere((s) => s.channelId == settings.channelId);
      
      if (index >= 0) {
        existingSettings[index] = settings;
      } else {
        existingSettings.add(settings);
      }
    } else {
      _contentDistributionSettings[contentId] = [settings];
    }
    
    return settings;
  }

  @override
  Future<bool> publishToChannel(String contentId, String channelId) async {
    final channel = _distributionChannels[channelId];
    final workflow = await _workflowService.getWorkflow(contentId);

    if (channel == null) {
      throw Exception('Distribution channel not found');
    }

    if (workflow == null) {
      throw Exception('Content workflow not found');
    }

    if (!channel.isActive) {
      throw Exception('Distribution channel is not active');
    }

    try {
      // Process content for the specific platform
      final processingResult = await _contentProcessingService.processContentForPlatform(
        workflow,
        channel.platform,
        channel.settings,
      );

      if (!processingResult.isSuccess) {
        throw Exception('Content processing failed for platform ${channel.platform}: ${processingResult.errorMessage}');
      }

      // In a real implementation, this would make API calls to the platform
      // For now, we'll just simulate the publishing process
      if (kDebugMode) {
        print('Publishing content $contentId to platform ${channel.platform}');
      }

      // Update workflow status
      await _workflowService.addDistributionInfo(contentId, channelId);

      return true;
    } catch (e) {
      // Log the error
      if (kDebugMode) {
        print('Failed to publish content $contentId to channel $channelId: $e');
      }
      
      // Update workflow with error info
      await _workflowService.addDistributionError(contentId, channelId, e.toString());
      
      return false;
    }
  }

  @override
  Future<List<bool>> publishToAllChannels(String contentId) async {
    final activeChannels = await getActiveDistributionChannels();
    final results = <bool>[];

    for (final channel in activeChannels) {
      final result = await publishToChannel(contentId, channel.id);
      results.add(result);
    }

    return results;
  }
}