import 'package:flutter/material.dart';

import '../../../domain/entities/distribution_channel.dart';
import '../../../domain/entities/distribution_settings.dart';

class DistributionSettingsWidget extends StatefulWidget {
  final List<DistributionChannel> channels;
  final List<DistributionSettings> currentSettings;
  final Function(List<DistributionSettings>) onSave;

  const DistributionSettingsWidget({
    super.key,
    required this.channels,
    required this.currentSettings,
    required this.onSave,
  });

  @override
  State<DistributionSettingsWidget> createState() => _DistributionSettingsWidgetState();
}

class _DistributionSettingsWidgetState extends State<DistributionSettingsWidget> {
  late List<DistributionSettings> _settings;

  @override
  void initState() {
    super.initState();
    _settings = List.from(widget.currentSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribution Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Select channels for distribution:'),
        const SizedBox(height: 8),
        ...widget.channels.map((channel) {
          final channelSettings = _settings.firstWhere(
            (setting) => setting.channelId == channel.id,
            orElse: () => DistributionSettings(
              channelId: channel.id,
              contentId: 'new_content',
              platformSpecificSettings: {},
              hashtags: [],
              optimizeForPlatform: true,
            ),
          );
          
          return _ChannelSettingsItem(
            channel: channel,
            settings: channelSettings,
            onChanged: (newSettings) {
              setState(() {
                final index = _settings.indexWhere((s) => s.channelId == channel.id);
                if (index >= 0) {
                  _settings[index] = newSettings;
                } else {
                  _settings.add(newSettings);
                }
              });
            },
          );
        }).toList(),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => widget.onSave(_settings),
          child: const Text('Save Distribution Settings'),
        ),
      ],
    );
  }
}

class _ChannelSettingsItem extends StatefulWidget {
  final DistributionChannel channel;
  final DistributionSettings settings;
  final Function(DistributionSettings) onChanged;

  const _ChannelSettingsItem({
    required this.channel,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<_ChannelSettingsItem> createState() => _ChannelSettingsItemState();
}

class _ChannelSettingsItemState extends State<_ChannelSettingsItem> {
  late TextEditingController _captionController;
  late TextEditingController _hashtagsController;
  late bool _optimizeForPlatform;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.settings.customCaption);
    _hashtagsController = TextEditingController(text: widget.settings.hashtags.join(' '));
    _optimizeForPlatform = widget.settings.optimizeForPlatform;
  }

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.channel.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: widget.channel.isActive,
                  onChanged: (value) {
                    // In a real implementation, this would update the channel status
                    // For now, we'll just toggle the local state
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.channel.platform),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Custom Caption',
                hintText: 'Enter a custom caption for this platform',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hashtagsController,
              decoration: const InputDecoration(
                labelText: 'Hashtags',
                hintText: 'Enter hashtags separated by spaces',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _optimizeForPlatform,
                  onChanged: (value) {
                    setState(() {
                      _optimizeForPlatform = value ?? false;
                    });
                  },
                ),
                const Text('Optimize for platform'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}