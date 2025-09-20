import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/content/content.dart';
import '../../services/publishing/publishing_service.dart';
import 'content_editor.dart';
import 'content_details.dart';

class ContentDashboard extends StatefulWidget {
  final PublishingService publishingService;

  const ContentDashboard({
    Key? key,
    required this.publishingService,
  }) : super(key: key);

  @override
  _ContentDashboardState createState() => _ContentDashboardState();
}

class _ContentDashboardState extends State<ContentDashboard> {
  ContentStatus? _selectedStatus;
  String _searchQuery = '';
  bool _showOnlyMyContent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewContent,
            tooltip: 'Create New Content',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Content',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusTabs(),
          _buildSearchBar(),
          Expanded(
            child: _buildContentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatusTab(null, 'All'),
          _buildStatusTab(ContentStatus.draft, 'Draft'),
          _buildStatusTab(ContentStatus.review, 'In Review'),
          _buildStatusTab(ContentStatus.scheduled, 'Scheduled'),
          _buildStatusTab(ContentStatus.published, 'Published'),
          _buildStatusTab(ContentStatus.archived, 'Archived'),
        ],
      ),
    );
  }

  Widget _buildStatusTab(ContentStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
          });
        },
        backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
        selectedColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search content...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('My Content'),
            selected: _showOnlyMyContent,
            onSelected: (selected) {
              setState(() {
                _showOnlyMyContent = selected;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return AnimatedBuilder(
      animation: widget.publishingService,
      builder: (context, child) {
        if (widget.publishingService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.publishingService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${widget.publishingService.error}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => widget.publishingService.fetchContents(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var filteredContents = widget.publishingService.contents;

        if (_selectedStatus != null) {
          filteredContents = filteredContents.where((c) => c.status == _selectedStatus).toList();
        }

        if (_searchQuery.isNotEmpty) {
          filteredContents = filteredContents.where((c) =>
              c.title.toLowerCase().contains(_searchQuery) ||
              c.description.toLowerCase().contains(_searchQuery)).toList();
        }

        if (filteredContents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No content found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or create new content',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredContents.length,
          itemBuilder: (context, index) {
            final content = filteredContents[index];
            return ContentListItem(
              content: content,
              onTap: () => _viewContent(content),
              onEdit: () => _editContent(content),
              onDelete: () => _deleteContent(content),
              onStatusChange: (newStatus) => _changeContentStatus(content, newStatus),
            );
          },
        );
      },
    );
  }

  void _createNewContent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentEditor(
          publishingService: widget.publishingService,
        ),
      ),
    );
  }

  void _viewContent(Content content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetails(
          content: content,
          publishingService: widget.publishingService,
        ),
      ),
    );
  }

  void _editContent(Content content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentEditor(
          publishingService: widget.publishingService,
          content: content,
        ),
      ),
    );
  }

  Future<void> _deleteContent(Content content) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Content'),
            content: Text('Are you sure you want to delete "${content.title}"?'),
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
      await widget.publishingService.deleteContent(content.id);
    }
  }

  Future<void> _changeContentStatus(Content content, ContentStatus newStatus) async {
    try {
      switch (newStatus) {
        case ContentStatus.review:
          await _showReviewDialog(content);
          break;
        case ContentStatus.scheduled:
          await _showScheduleDialog(content);
          break;
        case ContentStatus.published:
          await widget.publishingService.publishContent(content.id);
          break;
        case ContentStatus.archived:
          await widget.publishingService.archiveContent(content.id);
          break;
        case ContentStatus.draft:
          if (content.isArchived) {
            await widget.publishingService.restoreContent(content.id);
          }
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showReviewDialog(Content content) async {
    final reviewers = ['user1', 'user2', 'user3'];
    final selectedReviewers = <String>[];

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Submit for Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select reviewers:'),
              const SizedBox(height: 16),
              ...reviewers.map((reviewer) => CheckboxListTile(
                title: Text(reviewer),
                value: selectedReviewers.contains(reviewer),
                onChanged: (selected) {
                  setState(() {
                    if (selected!) {
                      selectedReviewers.add(reviewer);
                    } else {
                      selectedReviewers.remove(reviewer);
                    }
                  });
                },
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                if (selectedReviewers.isNotEmpty) {
                  await widget.publishingService.submitForReview(content.id, selectedReviewers);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleDialog(Content content) async {
    final scheduledDate = DateTime.now().add(const Duration(days: 1));

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: scheduledDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time != null) {
                    final scheduledDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                    Navigator.of(context).pop(true);
                    await widget.publishingService.scheduleContent(content.id, scheduledDateTime);
                  }
                }
              },
              child: const Text('Select Date & Time'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Show only my content'),
              value: _showOnlyMyContent,
              onChanged: (value) {
                setState(() {
                  _showOnlyMyContent = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ContentListItem extends StatelessWidget {
  final Content content;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(ContentStatus) onStatusChange;

  const ContentListItem({
    Key? key,
    required this.content,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          content.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(),
                const SizedBox(width: 8),
                Text(
                  'Updated ${_formatDate(content.updatedAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
              case 'review':
                onStatusChange(ContentStatus.review);
                break;
              case 'schedule':
                onStatusChange(ContentStatus.scheduled);
                break;
              case 'publish':
                onStatusChange(ContentStatus.published);
                break;
              case 'archive':
                onStatusChange(ContentStatus.archived);
                break;
              case 'restore':
                onStatusChange(ContentStatus.draft);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
            if (content.isDraft) ...[
              const PopupMenuItem(value: 'review', child: Text('Submit for Review')),
              const PopupMenuItem(value: 'schedule', child: Text('Schedule')),
              const PopupMenuItem(value: 'publish', child: Text('Publish')),
            ],
            if (content.isScheduled) ...[
              const PopupMenuItem(value: 'publish', child: Text('Publish Now')),
            ],
            if (content.isPublished) ...[
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
            if (content.isArchived) ...[
              const PopupMenuItem(value: 'restore', child: Text('Restore')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (content.status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}