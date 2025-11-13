import 'package:flutter/material.dart';
';
import '../../../core/data/services/accessibility/caption_service.dart';

/// Debug accessibility page for visualizing captions, transcript sync, and focus order
/// AC8: Debug surface toggled from developer menu
class StoryAccessibilityPage extends StatefulWidget {
  final String storyId;
  final List<CaptionCue> captionCues;
  final Duration currentPosition;

  const StoryAccessibilityPage({
    super.key,
    required this.storyId,
    required this.captionCues,
    required this.currentPosition,
  });

  @override
  State<StoryAccessibilityPage> createState() => _StoryAccessibilityPageState();
}

class _StoryAccessibilityPageState extends State<StoryAccessibilityPage> {
  final List<FocusNode> _focusNodes = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Create focus nodes for each tab
    for (int i = 0; i < 3; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAccessibilityInfo(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(),

          // Content area
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildCaptionVisualization(),
                _buildTranscriptSync(),
                _buildFocusOrder(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Captions'),
          _buildTab(1, 'Transcript Sync'),
          _buildTab(2, 'Focus Order'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: Focus(
        focusNode: _focusNodes[index],
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTabIndex = index;
            });
            _focusNodes[index].requestFocus();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: isSelected
                  ? Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionVisualization() {
    final captionService = CaptionService();
    final activeCues = captionService.getActiveCues(
      widget.captionCues,
      widget.currentPosition,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caption Visualization',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Current Position: ${_formatDuration(widget.currentPosition)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Active Cues: ${activeCues.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ...widget.captionCues.asMap().entries.map((entry) {
            final index = entry.key;
            final cue = entry.value;
            final isActive = activeCues.contains(cue);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${_formatDuration(cue.start)} → ${_formatDuration(cue.end)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      cue.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTranscriptSync() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TranscriptPanel(
        cues: widget.captionCues,
        currentPosition: widget.currentPosition,
        onSeek: (position) {
          // In a real implementation, this would seek the video
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Would seek to ${_formatDuration(position)}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFocusOrder() {
    final focusOrder = <String>[
      'Video Player',
      'Play/Pause Button',
      'Caption Toggle',
      'Transcript Panel',
      'Search Box',
      'Transcript List',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Order',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Expected focus order for keyboard navigation:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...focusOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAccessibilityInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Debug Info'),
        content: const SingleChildScrollView(
          child: Text(
            'This page helps visualize accessibility features:\n\n'
            '• Caption Visualization: Shows all caption cues and highlights active ones\n'
            '• Transcript Sync: Interactive transcript panel with search\n'
            '• Focus Order: Expected keyboard navigation order\n\n'
            'Use Tab/Shift+Tab to navigate between elements.\n'
            'Use Arrow keys to navigate within lists.',
          ),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000 ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '$milliseconds';
  }
}
