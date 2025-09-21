import 'package:flutter/foundation.dart';

import '../entities/distribution_channel.dart';

abstract class DistributionRepository {
  /// Get a distribution channel by ID
  Future<DistributionChannel?> getDistributionChannel(String id);

  /// Get all distribution channels
  Future<List<DistributionChannel>> getAllDistributionChannels();

  /// Get active distribution channels
  Future<List<DistributionChannel>> getActiveDistributionChannels();

  /// Create a new distribution channel
  Future<DistributionChannel> createDistributionChannel(DistributionChannel channel);

  /// Update an existing distribution channel
  Future<DistributionChannel> updateDistributionChannel(DistributionChannel channel);

  /// Delete a distribution channel
  Future<bool> deleteDistributionChannel(String id);

  /// Get distribution settings for a content
  Future<List<DistributionSettings>> getDistributionSettingsForContent(String contentId);

  /// Update distribution settings for a content
  Future<DistributionSettings> updateDistributionSettings(DistributionSettings settings);

  /// Publish content to a specific channel
  Future<bool> publishToChannel(String contentId, String channelId);

  /// Publish content to all active channels
  Future<List<bool>> publishToAllChannels(String contentId);
}