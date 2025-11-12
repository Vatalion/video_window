import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/share_response.dart';

class StoryShareSheet extends StatelessWidget {
  final ShareResponse shareResponse;

  const StoryShareSheet({super.key, required this.shareResponse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share Story', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(shareResponse.socialPreview.title,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(shareResponse.socialPreview.description,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share with apps'),
            onTap: () {
              Share.share(shareResponse.deepLink,
                  subject: shareResponse.socialPreview.title);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy link'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: shareResponse.deepLink));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard!')),
              );
            },
          ),
          const SizedBox(height: 8),
          Text('Link expires at: ${shareResponse.expiresAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
