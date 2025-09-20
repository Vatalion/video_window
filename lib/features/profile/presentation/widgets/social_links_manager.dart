import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/profile_bloc.dart';

class SocialLinksManager extends StatefulWidget {
  const SocialLinksManager({super.key});

  @override
  State<SocialLinksManager> createState() => _SocialLinksManagerState();
}

class _SocialLinksManagerState extends State<SocialLinksManager> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is SocialLinksUpdated) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Social links updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProfileError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social Links'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _isLoading ? null : _addSocialLink,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  if (state is ProfileLoaded) {
                    return _buildSocialLinksList(state.profile.socialLinks);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinksList(List<SocialLinkModel> links) {
    if (links.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No social links added yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your social media profiles to connect with others',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _addSocialLink,
              icon: const Icon(Icons.add),
              label: const Text('Add Social Link'),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: links.length,
      onReorder: (oldIndex, newIndex) {
        _reorderLinks(links, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final link = links[index];
        return _buildSocialLinkCard(link, index);
      },
    );
  }

  Widget _buildSocialLinkCard(SocialLinkModel link, int index) {
    return Card(
      key: ValueKey(link.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              link.platform.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          link.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(link.displayUrl),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await _editSocialLink(link);
                break;
              case 'delete':
                await _deleteSocialLink(link);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSocialLink() async {
    await _showSocialLinkDialog();
  }

  Future<void> _editSocialLink(SocialLinkModel link) async {
    await _showSocialLinkDialog(link: link);
  }

  Future<void> _deleteSocialLink(SocialLinkModel link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Social Link'),
        content: Text('Are you sure you want to delete your ${link.platform.displayName} link?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      context.read<ProfileBloc>().add(
        DeleteSocialLink(linkId: link.id),
      );
    }
  }

  Future<void> _reorderLinks(List<SocialLinkModel> links, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = links.removeAt(oldIndex);
    links.insert(newIndex, item);

    final linkIds = links.map((link) => link.id).toList();
    context.read<ProfileBloc>().add(ReorderSocialLinks(linkIds: linkIds));
  }

  Future<void> _showSocialLinkDialog({SocialLinkModel? link}) async {
    final platformController = TextEditingController(text: link?.platform.name);
    final urlController = TextEditingController(text: link?.url);
    final usernameController = TextEditingController(text: link?.username);
    final formKey = GlobalKey<FormState>();

    SocialPlatform? selectedPlatform = link?.platform;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(link == null ? 'Add Social Link' : 'Edit Social Link'),
          content: Form(
            key: formKey,
            child: Column(
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
                          Text(platform.icon),
                          const SizedBox(width: 8),
                          Text(platform.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPlatform = value;
                      platformController.text = value?.name ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a platform';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: selectedPlatform == SocialPlatform.website
                        ? 'Website URL'
                        : 'Profile URL',
                    border: const OutlineInputBorder(),
                    hintText: selectedPlatform?.urlTemplate.replaceAll('{username}', 'username'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a URL';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                ),
                if (selectedPlatform != SocialPlatform.website) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: '${selectedPlatform?.displayName} Username',
                      border: const OutlineInputBorder(),
                      hintText: 'your_username',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);

                  if (link == null) {
                    // Add new link
                    context.read<ProfileBloc>().add(
                      AddSocialLink(
                        platform: selectedPlatform!,
                        url: urlController.text.trim(),
                        username: usernameController.text.trim().isNotEmpty
                            ? usernameController.text.trim()
                            : null,
                      ),
                    );
                  } else {
                    // Update existing link
                    context.read<ProfileBloc>().add(
                      UpdateSocialLink(
                        linkId: link.id,
                        platform: selectedPlatform!,
                        url: urlController.text.trim(),
                        username: usernameController.text.trim().isNotEmpty
                            ? usernameController.text.trim()
                            : null,
                      ),
                    );
                  }
                }
              },
              child: Text(link == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}