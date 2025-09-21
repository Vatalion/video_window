import 'package:flutter/material.dart';

import '../../domain/entities/distribution_channel.dart';
import '../../domain/entities/distribution_settings.dart';
import '../widgets/distribution/distribution_channel_list_widget.dart';
import '../widgets/distribution/distribution_settings_widget.dart';

class DistributionManagementScreen extends StatefulWidget {
  const DistributionManagementScreen({super.key});

  @override
  State<DistributionManagementScreen> createState() => _DistributionManagementScreenState();
}

class _DistributionManagementScreenState extends State<DistributionManagementScreen> {
  // In a real implementation, these would come from a service
  List<DistributionChannel> _channels = [];
  List<DistributionSettings> _contentSettings = [];
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distribution Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isEditing
            ? _buildSettingsEditor()
            : DistributionChannelListWidget(
                channels: _channels,
                onChannelSelected: _onChannelSelected,
                onChannelToggled: _onChannelToggled,
                onChannelCreated: _onChannelCreated,
              ),
      ),
    );
  }

  Widget _buildSettingsEditor() {
    return DistributionSettingsWidget(
      channels: _channels,
      currentSettings: _contentSettings,
      onSave: _onSettingsSaved,
    );
  }

  void _onChannelSelected(DistributionChannel channel) {
    // In a real implementation, this would show channel details or settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected channel: ${channel.name}')),
    );
  }

  void _onChannelToggled(DistributionChannel channel) {
    setState(() {
      final index = _channels.indexWhere((c) => c.id == channel.id);
      if (index >= 0) {
        _channels[index] = channel.copyWith(
          isActive: !channel.isActive,
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  void _onChannelCreated() {
    // In a real implementation, this would show a channel creation form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new distribution channel')),
    );
  }

  void _onSettingsSaved(List<DistributionSettings> settings) {
    setState(() {
      _contentSettings = settings;
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Distribution settings saved')),
    );
  }
}