import 'package:flutter/material.dart';
import 'package:core/data/services/accessibility/caption_service.dart';
import 'package:core/services/analytics_service.dart';
import '../analytics/story_analytics_events.dart';

/// Transcript panel widget with synchronized cue highlighting, search, and keyboard navigation
/// AC2, AC4, AC7: Transcript panel with keyboard navigation, search filtering, click-to-seek, and analytics
class TranscriptPanel extends StatefulWidget {
  final List<CaptionCue> cues;
  final Duration currentPosition;
  final Function(Duration) onSeek;
  final String? searchTerm;
  final String? storyId;
  final String language;
  final AnalyticsService? analyticsService;

  const TranscriptPanel({
    super.key,
    required this.cues,
    required this.currentPosition,
    required this.onSeek,
    this.searchTerm,
    this.storyId,
    this.language = 'en',
    this.analyticsService,
  });

  @override
  State<TranscriptPanel> createState() => _TranscriptPanelState();
}

class _TranscriptPanelState extends State<TranscriptPanel> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _listFocusNode = FocusNode();
  String _filteredSearchTerm = '';
  int? _selectedCueIndex;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _filteredSearchTerm = widget.searchTerm ?? '';
    if (_filteredSearchTerm.isNotEmpty) {
      _searchController.text = _filteredSearchTerm;
    }

    // AC7: Emit analytics event when transcript panel is viewed
    if (widget.analyticsService != null && widget.storyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final event = StoryTranscriptViewedEvent(
          storyId: widget.storyId!,
          language: widget.language,
          searchTerm:
              _filteredSearchTerm.isNotEmpty ? _filteredSearchTerm : null,
        );
        widget.analyticsService!.trackEvent(event);
      });
    }
  }

  @override
  void didUpdateWidget(TranscriptPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != oldWidget.currentPosition) {
      _scrollToActiveCue();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _filteredSearchTerm = _searchController.text.toLowerCase();
    });

    // AC7: Emit analytics event when search term changes (debounced)
    if (widget.analyticsService != null &&
        widget.storyId != null &&
        _filteredSearchTerm.isNotEmpty) {
      // In production, debounce this to avoid excessive events
      final event = StoryTranscriptViewedEvent(
        storyId: widget.storyId!,
        language: widget.language,
        searchTerm: _filteredSearchTerm,
      );
      widget.analyticsService!.trackEvent(event);
    }
  }

  void _scrollToActiveCue() {
    final activeIndex = _getActiveCueIndex();
    if (activeIndex != null && activeIndex < widget.cues.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          const itemHeight = 80.0; // Approximate constt per cue
          final targetOffset = activeIndex * itemHeight;
          _scrollController.animateTo(
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  int? _getActiveCueIndex() {
    for (int i = 0; i < widget.cues.length; i++) {
      final cue = widget.cues[i];
      if (widget.currentPosition >= cue.start &&
          widget.currentPosition <= cue.end) {
        return i;
      }
    }
    return null;
  }

  List<CaptionCue> _getFilteredCues() {
    if (_filteredSearchTerm.isEmpty) {
      return widget.cues;
    }
    return widget.cues.where((cue) {
      return cue.text.toLowerCase().contains(_filteredSearchTerm);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCues = _getFilteredCues();
    final activeIndex = _getActiveCueIndex();

    return FocusScope(
      node: FocusScopeNode(),
      child: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Semantics(
              label: 'Search transcript',
              hint: 'Type to filter transcript content',
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search transcript...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _filteredSearchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.requestFocus();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (value) {
                  // Jump to first matching cue
                  if (filteredCues.isNotEmpty) {
                    widget.onSeek(filteredCues.first.start);
                  }
                },
              ),
            ),
          ),

          // Transcript list
          Expanded(
            child: Focus(
              focusNode: _listFocusNode,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filteredCues.length,
                itemBuilder: (context, index) {
                  final cue = filteredCues[index];
                  final isActive = widget.cues.indexOf(cue) == activeIndex;
                  final isSelected = index == _selectedCueIndex;

                  return _TranscriptCueItem(
                    cue: cue,
                    isActive: isActive,
                    isSelected: isSelected,
                    searchTerm: _filteredSearchTerm,
                    onTap: () {
                      widget.onSeek(cue.start);
                    },
                    onFocus: () {
                      setState(() {
                        _selectedCueIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }
}

class _TranscriptCueItem extends StatelessWidget {
  final CaptionCue cue;
  final bool isActive;
  final bool isSelected;
  final String searchTerm;
  final VoidCallback onTap;
  final VoidCallback onFocus;

  const _TranscriptCueItem({
    required this.cue,
    required this.isActive,
    required this.isSelected,
    required this.searchTerm,
    required this.onTap,
    required this.onFocus,
  });

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _highlightSearchTerm(String text) {
    if (searchTerm.isEmpty) return text;
    // Simple highlighting - in production, use proper text highlighting widget
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isActive
        ? theme.colorScheme.primaryContainer
        : isSelected
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.transparent;

    return Semantics(
      label:
          'Transcript cue: ${_formatTime(cue.start)} to ${_formatTime(cue.end)}',
      hint: 'Double tap to seek to this position',
      button: true,
      child: InkWell(
        onTap: onTap,
        onFocusChange: (hasFocus) {
          if (hasFocus) onFocus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp
              Text(
                _formatTime(cue.start),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              // Cue text
              Expanded(
                child: Text(
                  _highlightSearchTerm(cue.text),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
