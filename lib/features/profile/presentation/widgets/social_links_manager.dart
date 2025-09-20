import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/social_link.dart';
import '../../data/repositories/profile_repository.dart';

class SocialLinksManager extends StatefulWidget {
  final String userId;
  final List<SocialLink> initialLinks;
  final Function(List<SocialLink>) onLinksUpdated;

  const SocialLinksManager({
    super.key,
    required this.userId,
    required this.initialLinks,
    required this.onLinksUpdated,
  });

  @override
  State<SocialLinksManager> createState() => _SocialLinksManagerState();
}

class _SocialLinksManagerState extends State<SocialLinksManager> {
  final ProfileRepository _repository = ProfileRepository();
  late List<SocialLink> _links;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _links = List.from(widget.initialLinks);
  }

  Future<void> _addSocialLink(SocialPlatform platform, String url) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newLink = SocialLink(
        userId: widget.userId,
        platform: platform,
        url: url,
        displayOrder: _links.length,
      );

      final savedLink = await _repository.addSocialLink(newLink);

      setState(() {
        _links.add(savedLink);
        _isLoading = false;
      });

      widget.onLinksUpdated(_links);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add link: ${e.toString()}')),
        );
      }
    }
  }

  void _removeSocialLink(int index) {
    setState(() {
      _links.removeAt(index);
    });
    widget.onLinksUpdated(_links);
  }

  void _showAddLinkDialog() {
    SocialPlatform? selectedPlatform;
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Social Link'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SocialPlatform>(
                  value: selectedPlatform,
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                  ),
                  items: SocialPlatform.values.map((platform) {
                    return DropdownMenuItem(
                      value: platform,
                      child: Row(
                        children: [
                          Text(_getPlatformIcon(platform)),
                          const SizedBox(width: 8),
                          Text(_getPlatformName(platform)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPlatform = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedPlatform == null || urlController.text.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        _addSocialLink(selectedPlatform!, urlController.text);
                      },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getPlatformIcon(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.twitter:
        return '🐦';
      case SocialPlatform.instagram:
        return '📷';
      case SocialPlatform.facebook:
        return '📘';
      case SocialPlatform.linkedin:
        return '💼';
      case SocialPlatform.youtube:
        return '🎥';
      case SocialPlatform.tiktok:
        return '🎵';
      case SocialPlatform.github:
        return '💻';
      case SocialPlatform.website:
        return '🌐';
    }
  }

  String _getPlatformName(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.twitter:
        return 'Twitter';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.linkedin:
        return 'LinkedIn';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.github:
        return 'GitHub';
      case SocialPlatform.website:
        return 'Website';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Social Links',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _showAddLinkDialog,
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_links.isEmpty)
              const Center(
                child: Text(
                  'No social links added yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _links.removeAt(oldIndex);
                    _links.insert(newIndex, item);

                    // Update display orders
                    for (int i = 0; i < _links.length; i++) {
                      _links[i] = _links[i].copyWith(displayOrder: i);
                    }
                  });
                  widget.onLinksUpdated(_links);
                },
                children: [
                  for (int index = 0; index < _links.length; index++)
                    _buildSocialLinkTile(_links[index], index),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinkTile(SocialLink link, int index) {
    return Card(
      key: ValueKey(link.platform),
      child: ListTile(
        leading: Text(
          _getPlatformIcon(link.platform),
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(_getPlatformName(link.platform)),
        subtitle: Text(
          link.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _launchUrl(link.url),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeSocialLink(index),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }
}