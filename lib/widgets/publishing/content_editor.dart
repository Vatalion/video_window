import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/content/content.dart';
import '../../services/publishing/publishing_service.dart';

class ContentEditor extends StatefulWidget {
  final PublishingService publishingService;
  final Content? content;

  const ContentEditor({
    Key? key,
    required this.publishingService,
    this.content,
  }) : super(key: key);

  @override
  _ContentEditorState createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<String> _tags = [];
  List<MediaAsset> _mediaAssets = [];
  bool _isPublic = true;
  bool _allowComments = true;
  bool _allowSharing = true;
  DateTime? _publishAt;
  DateTime? _expireAt;

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _loadContent();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _loadContent() {
    final content = widget.content!;
    _titleController.text = content.title;
    _descriptionController.text = content.description;
    _bodyController.text = content.body;
    _tags = List.from(content.tags);
    _mediaAssets = List.from(content.mediaAssets);
    _isPublic = content.publishSettings.isPublic;
    _allowComments = content.publishSettings.allowComments;
    _allowSharing = content.publishSettings.allowSharing;
    _publishAt = content.publishSettings.publishAt;
    _expireAt = content.publishSettings.expireAt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content == null ? 'Create Content' : 'Edit Content'),
        actions: [
          if (widget.content != null && widget.content!.isDraft)
            TextButton(
              onPressed: _saveAsDraft,
              child: const Text('Save Draft'),
            ),
          if (widget.content != null)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'preview', child: Text('Preview')),
                const PopupMenuItem(value: 'versions', child: Text('Version History')),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildTagsField(),
              const SizedBox(height: 16),
              _buildMediaSection(),
              const SizedBox(height: 16),
              _buildBodyField(),
              const SizedBox(height: 16),
              _buildPublishingOptions(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
        hintText: 'Enter content title',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        hintText: 'Enter content description',
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        return null;
      },
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _tagsController,
          decoration: InputDecoration(
            labelText: 'Tags',
            border: const OutlineInputBorder(),
            hintText: 'Enter tags separated by commas',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
              tooltip: 'Add tag',
            ),
          ),
          onFieldSubmitted: (_) => _addTag(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _tags.map((tag) => Chip(
            label: Text(tag),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () => _removeTag(tag),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Media Assets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera),
                  onPressed: _captureImage,
                  tooltip: 'Capture Image',
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: _pickImage,
                  tooltip: 'Pick Image',
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: _pickVideo,
                  tooltip: 'Pick Video',
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFile,
                  tooltip: 'Attach File',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_mediaAssets.isNotEmpty)
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mediaAssets.length,
              itemBuilder: (context, index) {
                final asset = _mediaAssets[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.grey[200],
                            child: Icon(
                              _getAssetIcon(asset.type),
                              size: 32,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            asset.filename ?? asset.type,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBodyField() {
    return TextFormField(
      controller: _bodyController,
      decoration: const InputDecoration(
        labelText: 'Content Body',
        border: OutlineInputBorder(),
        hintText: 'Enter content body',
        alignLabelWithHint: true,
      ),
      maxLines: 15,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Content body is required';
        }
        return null;
      },
    );
  }

  Widget _buildPublishingOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Publishing Options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public'),
              subtitle: const Text('Make this content publicly visible'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            SwitchListTile(
              title: const Text('Allow Comments'),
              subtitle: const Text('Allow users to comment on this content'),
              value: _allowComments,
              onChanged: (value) => setState(() => _allowComments = value),
            ),
            SwitchListTile(
              title: const Text('Allow Sharing'),
              subtitle: const Text('Allow users to share this content'),
              value: _allowSharing,
              onChanged: (value) => setState(() => _allowSharing = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Publish Date'),
              subtitle: Text(_publishAt != null
                  ? 'Scheduled for ${_formatDate(_publishAt!)}'
                  : 'Publish immediately'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectPublishDate,
              ),
            ),
            ListTile(
              title: const Text('Expire Date'),
              subtitle: Text(_expireAt != null
                  ? 'Expires on ${_formatDate(_expireAt!)}'
                  : 'Never expires'),
              trailing: IconButton(
                icon: const Icon(Icons.event_busy),
                onPressed: _selectExpireDate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveContent,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.content == null ? 'Create' : 'Update'),
          ),
        ),
      ],
    );
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _addMediaAsset(MediaAsset(
        id: 'asset_${DateTime.now().millisecondsSinceEpoch}',
        url: image.path,
        type: 'image',
        filename: image.name,
        size: await image.length(),
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _addMediaAsset(MediaAsset(
        id: 'asset_${DateTime.now().millisecondsSinceEpoch}',
        url: image.path,
        type: 'image',
        filename: image.name,
        size: await image.length(),
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _addMediaAsset(MediaAsset(
        id: 'asset_${DateTime.now().millisecondsSinceEpoch}',
        url: video.path,
        type: 'video',
        filename: video.name,
        size: await video.length(),
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<void> _pickFile() async {
  }

  void _addMediaAsset(MediaAsset asset) {
    setState(() {
      _mediaAssets.add(asset);
    });
  }

  IconData _getAssetIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.music_note;
      case 'document':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _selectPublishDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (time != null) {
        setState(() {
          _publishAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectExpireDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expireAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );
      if (time != null) {
        setState(() {
          _expireAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final wordCount = _bodyController.text.split(' ').length;
      final estimatedReadTime = (wordCount / 200).ceil();

      final content = Content(
        id: widget.content?.id ?? 'content_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descriptionController.text,
        body: _bodyController.text,
        status: widget.content?.status ?? ContentStatus.draft,
        authorId: 'current_user_id',
        tags: _tags,
        mediaAssets: _mediaAssets,
        publishSettings: PublishSettings(
          isPublic: _isPublic,
          allowComments: _allowComments,
          allowSharing: _allowSharing,
          publishAt: _publishAt,
          expireAt: _expireAt,
          targetPlatforms: ['web', 'mobile'],
        ),
        metadata: ContentMetadata(
          estimatedReadTime: estimatedReadTime,
          wordCount: wordCount,
          excerpt: _descriptionController.text.length > 200
              ? '${_descriptionController.text.substring(0, 200)}...'
              : _descriptionController.text,
        ),
        createdAt: widget.content?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: widget.content?.publishedAt,
        scheduledAt: widget.content?.scheduledAt,
        versions: widget.content?.versions ?? [],
        approvalRequests: widget.content?.approvalRequests ?? [],
        analytics: widget.content?.analytics ?? AnalyticsData(
          views: 0,
          likes: 0,
          comments: 0,
          shares: 0,
          engagementRate: 0.0,
          platformViews: {},
        ),
      );

      if (widget.content == null) {
        await widget.publishingService.createContent(content);
      } else {
        await widget.publishingService.updateContent(widget.content!.id, content);
      }

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAsDraft() async {
    if (_formKey.currentState!.validate()) {
      await _saveContent();
    }
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'preview':
        _previewContent();
        break;
      case 'versions':
        _showVersionHistory();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  void _previewContent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview functionality coming soon!')),
    );
  }

  void _showVersionHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Version history coming soon!')),
    );
  }

  void _showSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon!')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}