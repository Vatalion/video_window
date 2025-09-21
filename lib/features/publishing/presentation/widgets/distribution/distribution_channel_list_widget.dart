import 'package:flutter/material.dart';

import '../../../domain/entities/distribution_channel.dart';

class DistributionChannelListWidget extends StatelessWidget {
  final List<DistributionChannel> channels;
  final Function(DistributionChannel) onChannelSelected;
  final Function(DistributionChannel) onChannelToggled;
  final Function() onChannelCreated;

  const DistributionChannelListWidget({
    super.key,
    required this.channels,
    required this.onChannelSelected,
    required this.onChannelToggled,
    required this.onChannelCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Distribution Channels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onChannelCreated,
            ),
          ],
        ),
        if (channels.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No distribution channels found. Add your first channel!'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return _DistributionChannelListItem(
                  channel: channel,
                  onTap: () => onChannelSelected(channel),
                  onToggle: () => onChannelToggled(channel),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DistributionChannelListItem extends StatelessWidget {
  final DistributionChannel channel;
  final Function() onTap;
  final Function() onToggle;

  const _DistributionChannelListItem({
    required this.channel,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(channel.name),
        subtitle: Text(channel.platform),
        trailing: Switch(
          value: channel.isActive,
          onChanged: (value) => onToggle(),
        ),
        onTap: onTap,
      ),
    );
  }
}