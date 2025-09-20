import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/content/content.dart';
import '../../services/publishing/publishing_service.dart';

class ContentDetails extends StatefulWidget {
  final Content content;
  final PublishingService publishingService;

  const ContentDetails({
    Key? key,
    required this.content,
    required this.publishingService,
  }) : super(key: key);

  @override
  _ContentDetailsState createState() => _ContentDetailsState();
}

class _ContentDetailsState extends State<ContentDetails> {
  late Content _content;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _content = widget.content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_content.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editContent,
            tooltip: 'Edit Content',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => _buildMenuItems(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildContentInfo(),
            const SizedBox(height: 24),
            _buildMediaAssets(),
            const SizedBox(height: 24),
            _buildWorkflowSection(),
            const SizedBox(height: 24),
            _buildAnalyticsSection(),
            const SizedBox(height: 24),
            _buildApprovalSection(),
            const SizedBox(height: 24),
            _buildVersionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatusChip(),
            const SizedBox(width: 8),
            if (_content.scheduledAt != null) ...[
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Scheduled for ${_formatDate(_content.scheduledAt!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _content.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _content.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'By ${_content.authorId}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(width: 16),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Created ${_formatDate(_content.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (_content.status) {
      case ContentStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
      case ContentStatus.review:
        color = Colors.orange;
        label = 'In Review';
        break;
      case ContentStatus.scheduled:
        color = Colors.blue;
        label = 'Scheduled';
        break;
      case ContentStatus.published:
        color = Colors.green;
        label = 'Published';
        break;
      case ContentStatus.archived:
        color = Colors.purple;
        label = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Content Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Word Count', '${_content.metadata.wordCount} words'),
            _buildInfoRow('Estimated Read Time', '${_content.metadata.estimatedReadTime} min'),
            _buildInfoRow('Tags', _content.tags.join(', ')),
            if (_content.publishSettings.isPublic)
              _buildInfoRow('Visibility', 'Public'),
            if (!_content.publishSettings.isPublic)
              _buildInfoRow('Visibility', 'Private'),
            if (_content.publishSettings.allowComments)
              _buildInfoRow('Comments', 'Enabled'),
            if (!_content.publishSettings.allowComments)
              _buildInfoRow('Comments', 'Disabled'),
            if (_content.publishSettings.allowSharing)
              _buildInfoRow('Sharing', 'Enabled'),
            if (!_content.publishSettings.allowSharing)
              _buildInfoRow('Sharing', 'Disabled'),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaAssets() {
    if (_content.mediaAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Media Assets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _content.mediaAssets.map((asset) => _buildMediaAssetCard(asset)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaAssetCard(MediaAsset asset) {
    return Container(
      width: 120,
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
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    asset.filename ?? asset.type,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatFileSize(asset.size),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Publishing Workflow',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildWorkflowTimeline(),
            const SizedBox(height: 16),
            _buildWorkflowActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowTimeline() {
    return Column(
      children: [
        _buildTimelineStep(
          'Draft',
          _content.createdAt,
          _content.isDraft || _content.isInReview || _content.isScheduled || _content.isPublished,
          'Content created',
        ),
        if (_content.isInReview || _content.isScheduled || _content.isPublished)
          _buildTimelineStep(
            'Review',
            _content.approvalRequests.isNotEmpty
                ? _content.approvalRequests.first.createdAt
                : DateTime.now(),
            _content.isInReview || _content.isScheduled || _content.isPublished,
            'Submitted for review',
          ),
        if (_content.isScheduled || _content.isPublished)
          _buildTimelineStep(
            'Scheduled',
            _content.scheduledAt ?? DateTime.now(),
            _content.isScheduled || _content.isPublished,
            'Scheduled for publishing',
          ),
        if (_content.isPublished)
          _buildTimelineStep(
            'Published',
            _content.publishedAt ?? DateTime.now(),
            true,
            'Published successfully',
          ),
        if (_content.isArchived)
          _buildTimelineStep(
            'Archived',
            _content.updatedAt,
            true,
            'Content archived',
          ),
      ],
    );
  }

  Widget _buildTimelineStep(String title, DateTime date, bool isCompleted, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (title != 'Archived') ...[
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
            ],
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.black : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(date),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowActions() {
    List<Widget> actions = [];

    if (_content.isDraft) {
      actions.add(ElevatedButton(
        onPressed: _submitForReview,
        child: const Text('Submit for Review'),
      ));
      actions.add(ElevatedButton(
        onPressed: _scheduleContent,
        child: const Text('Schedule'),
      ));
      actions.add(ElevatedButton(
        onPressed: _publishContent,
        child: const Text('Publish Now'),
      ));
    } else if (_content.isInReview) {
      actions.add(ElevatedButton(
        onPressed: _editContent,
        child: const Text('Edit Draft'),
      ));
    } else if (_content.isScheduled) {
      actions.add(ElevatedButton(
        onPressed: _publishContent,
        child: const Text('Publish Now'),
      ));
    } else if (_content.isPublished) {
      actions.add(ElevatedButton(
        onPressed: _archiveContent,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: const Text('Archive'),
      ));
    } else if (_content.isArchived) {
      actions.add(ElevatedButton(
        onPressed: _restoreContent,
        child: const Text('Restore'),
      ));
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
  }

  Widget _buildAnalyticsSection() {
    if (!_content.isPublished) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Views',
                    _content.analytics.views.toString(),
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Likes',
                    _content.analytics.likes.toString(),
                    Icons.thumb_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Comments',
                    _content.analytics.comments.toString(),
                    Icons.comment,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Shares',
                    _content.analytics.shares.toString(),
                    Icons.share,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Engagement Rate: ${(_content.analytics.engagementRate * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalSection() {
    if (_content.approvalRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approval Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._content.approvalRequests.map((request) => _buildApprovalRequestCard(request)),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalRequestCard(ApprovalRequest request) {
    Color statusColor;
    String statusText;

    switch (request.status) {
      case ApprovalStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case ApprovalStatus.approved:
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case ApprovalStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Request to: ${request.requestedTo}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (request.message != null) ...[
            const SizedBox(height: 8),
            Text(request.message!),
          ],
          if (request.responseMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              'Response: ${request.responseMessage}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Requested: ${_formatDate(request.createdAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          if (request.respondedAt != null)
            Text(
              'Responded: ${_formatDate(request.respondedAt!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildVersionHistory() {
    if (_content.versions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._content.versions.map((version) => _buildVersionCard(version)),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(ContentVersion version) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version ${version.versionNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatDate(version.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(version.title),
          if (version.changeLog != null) ...[
            const SizedBox(height: 8),
            Text(
              'Changes: ${version.changeLog}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [
      const PopupMenuItem(value: 'edit', child: Text('Edit')),
      const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
      const PopupMenuItem(value: 'export', child: Text('Export')),
    ];

    if (_content.isDraft) {
      items.add(const PopupMenuItem(value: 'delete', child: Text('Delete')));
    }

    if (_content.isPublished) {
      items.add(const PopupMenuItem(value: 'archive', child: Text('Archive')));
    }

    if (_content.isArchived) {
      items.add(const PopupMenuItem(value: 'restore', child: Text('Restore')));
    }

    return items;
  }

  void _handleMenuAction(String value) async {
    switch (value) {
      case 'edit':
        _editContent();
        break;
      case 'duplicate':
        _duplicateContent();
        break;
      case 'export':
        _exportContent();
        break;
      case 'delete':
        await _deleteContent();
        break;
      case 'archive':
        await _archiveContent();
        break;
      case 'restore':
        await _restoreContent();
        break;
    }
  }

  void _editContent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentEditor(
          publishingService: widget.publishingService,
          content: _content,
        ),
      ),
    ).then((_) {
      widget.publishingService.fetchContents();
    });
  }

  Future<void> _submitForReview() async {
    try {
      await widget.publishingService.submitForReview(_content.id, ['reviewer1', 'reviewer2']);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit for review: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _scheduleContent() async {
    final scheduledDate = DateTime.now().add(const Duration(days: 1));
    await widget.publishingService.scheduleContent(_content.id, scheduledDate);
    Navigator.of(context).pop();
  }

  Future<void> _publishContent() async {
    try {
      await widget.publishingService.publishContent(_content.id);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _archiveContent() async {
    try {
      await widget.publishingService.archiveContent(_content.id);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to archive: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreContent() async {
    try {
      await widget.publishingService.restoreContent(_content.id);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteContent() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Content'),
            content: Text('Are you sure you want to delete "${_content.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await widget.publishingService.deleteContent(_content.id);
      Navigator.of(context).pop();
    }
  }

  void _duplicateContent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate functionality coming soon!')),
    );
  }

  void _exportContent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon!')),
    );
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

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}