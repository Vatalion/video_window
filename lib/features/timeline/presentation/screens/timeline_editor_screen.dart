import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/text_overlay_settings.dart';
import '../../domain/entities/timeline_segment.dart';
import '../../domain/entities/timeline_track.dart';
import '../../domain/enums/segment_transition_type.dart';
import '../../domain/enums/timeline_track_type.dart';
import '../bloc/timeline_editor_cubit.dart';
import '../bloc/timeline_editor_state.dart';

class TimelineEditorScreen extends StatelessWidget {
  const TimelineEditorScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const TimelineEditorScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimelineEditorCubit(),
      child: const _TimelineEditorView(),
    );
  }
}

class _TimelineEditorView extends StatelessWidget {
  const _TimelineEditorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline Editor')),
      body: BlocBuilder<TimelineEditorCubit, TimelineEditorState>(
        builder: (context, state) {
          return Column(
            children: [
              _TimelineToolbar(state: state),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: _TracksPane(state: state)),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 320, child: _InspectorPane(state: state)),
                  ],
                ),
              ),
              _PlaybackControls(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineToolbar extends StatelessWidget {
  const _TimelineToolbar({required this.state});

  final TimelineEditorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimelineEditorCubit>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.view_timeline_outlined),
            const SizedBox(width: 8),
            Text(
              'Timeline length: ${_formatDuration(state.totalTimelineDuration)}',
            ),
            const Spacer(),
            ...state.tracks.map((track) {
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _TrackControls(track: track),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TrackControls extends StatelessWidget {
  const _TrackControls({required this.track});

  final TimelineTrack track;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimelineEditorCubit>();
    return Chip(
      avatar: Icon(
        track.type == TimelineTrackType.video
            ? Icons.video_settings_outlined
            : track.type == TimelineTrackType.audio
            ? Icons.audiotrack
            : Icons.text_fields,
        size: 16,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(track.type.label),
          const SizedBox(width: 8),
          Tooltip(
            message: track.isVisible ? 'Hide track' : 'Show track',
            child: IconButton(
              iconSize: 16,
              padding: EdgeInsets.zero,
              onPressed: () => cubit.toggleTrackVisibility(track.type),
              icon: Icon(
                track.isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          Tooltip(
            message: track.isLocked ? 'Unlock track' : 'Lock track',
            child: IconButton(
              iconSize: 16,
              padding: EdgeInsets.zero,
              onPressed: () => cubit.toggleTrackLock(track.type),
              icon: Icon(
                track.isLocked ? Icons.lock_outlined : Icons.lock_open_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TracksPane extends StatelessWidget {
  const _TracksPane({required this.state});

  final TimelineEditorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimelineEditorCubit>();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _PreviewCard(state: state),
        const SizedBox(height: 12),
        for (final track in state.tracks)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${track.type.label} Track',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (!track.isVisible)
                    const Text(
                      'Track hidden',
                      style: TextStyle(color: Colors.grey),
                    )
                  else if (track.segments.isEmpty)
                    const _EmptyTrackPlaceholder()
                  else
                    ReorderableListView.builder(
                      key: PageStorageKey('track-${track.type}'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) {
                        cubit.reorderSegment(track.type, oldIndex, newIndex);
                      },
                      itemCount: track.segments.length,
                      itemBuilder: (context, itemIndex) {
                        final segment = track.segments[itemIndex];
                        return _SegmentTile(
                          key: ValueKey(segment.id),
                          segment: segment,
                          isLocked: track.isLocked,
                          isSelected: state.selectedSegmentId == segment.id,
                          stepNumber: itemIndex + 1,
                          zoomLevel: state.zoomLevel,
                          onSelect: () => cubit.selectSegment(segment.id),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.state});

  final TimelineEditorState state;

  @override
  Widget build(BuildContext context) {
    final selectedSegment = state.selectedSegment;
    final progress = state.totalTimelineDuration.inMilliseconds == 0
        ? 0.0
        : state.currentPosition.inMilliseconds /
              state.totalTimelineDuration.inMilliseconds;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_outlined),
                const SizedBox(width: 8),
                Text(
                  selectedSegment?.title ?? 'Timeline Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(_formatDuration(state.currentPosition)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
            const SizedBox(height: 12),
            if (selectedSegment != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedSegment.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Overlay: ${selectedSegment.overlaySettings.content.isEmpty ? 'No text' : selectedSegment.overlaySettings.content}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              const Text('Select a segment to preview overlays and captions.'),
          ],
        ),
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    super.key,
    required this.segment,
    required this.isLocked,
    required this.isSelected,
    required this.stepNumber,
    required this.zoomLevel,
    required this.onSelect,
  });

  final TimelineSegment segment;
  final bool isLocked;
  final bool isSelected;
  final int stepNumber;
  final double zoomLevel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceVariant;
    final textColor = isSelected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    final clampedZoom = zoomLevel.clamp(0.5, 3.0);
    final tileHeight = (80 * clampedZoom).clamp(56, 200).toDouble();

    return Card(
      key: key,
      elevation: isSelected ? 4 : 0,
      color: color,
      child: SizedBox(
        height: tileHeight,
        child: ListTile(
          onTap: onSelect,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12 * clampedZoom,
          ),
          leading: Icon(
            segment.trackType == TimelineTrackType.video
                ? Icons.movie_creation_outlined
                : segment.trackType == TimelineTrackType.audio
                ? Icons.graphic_eq
                : Icons.text_fields,
          ),
          title: Text(
            segment.title,
            style: theme.textTheme.titleMedium?.copyWith(color: textColor),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                segment.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _InfoChip(
                    icon: Icons.flag_outlined,
                    label: 'Step $stepNumber',
                  ),
                  _InfoChip(
                    icon: Icons.av_timer,
                    label: _formatDuration(segment.duration),
                  ),
                  _InfoChip(
                    icon: Icons.auto_awesome_mosaic,
                    label: segment.transition.label,
                  ),
                  _InfoChip(
                    icon: Icons.closed_caption,
                    label: '${segment.captions.length} captions',
                  ),
                ],
              ),
            ],
          ),
          trailing: isLocked
              ? const Icon(Icons.lock_outline)
              : const Icon(Icons.drag_indicator_outlined),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label));
  }
}

class _EmptyTrackPlaceholder extends StatelessWidget {
  const _EmptyTrackPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_circle_outline, size: 32),
          SizedBox(height: 8),
          Text('Add timeline segments to begin editing'),
        ],
      ),
    );
  }
}

class _InspectorPane extends StatelessWidget {
  const _InspectorPane({required this.state});

  final TimelineEditorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimelineEditorCubit>();
    final selectedSegment = state.selectedSegment;

    if (selectedSegment == null) {
      return const Center(child: Text('Select a segment to edit details'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Segment Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('${selectedSegment.id}-title-field'),
            initialValue: selectedSegment.title,
            decoration: const InputDecoration(labelText: 'Title'),
            onChanged: (value) =>
                cubit.updateSegmentTitle(selectedSegment.id, value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('${selectedSegment.id}-description-field'),
            initialValue: selectedSegment.description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (value) =>
                cubit.updateSegmentDescription(selectedSegment.id, value),
          ),
          const SizedBox(height: 16),
          _DurationSlider(
            duration: selectedSegment.duration,
            onChanged: (newDuration) =>
                cubit.updateSegmentDuration(selectedSegment.id, newDuration),
          ),
          const SizedBox(height: 16),
          _TransitionSelector(
            segment: selectedSegment,
            onChanged: (transition) =>
                cubit.updateTransition(selectedSegment.id, transition),
            onDurationChanged: (duration) =>
                cubit.updateTransitionDuration(selectedSegment.id, duration),
          ),
          const SizedBox(height: 16),
          _OverlayEditor(
            segment: selectedSegment,
            onSettingsChanged: (settings) =>
                cubit.updateOverlaySettings(selectedSegment.id, settings),
          ),
          const SizedBox(height: 16),
          _CaptionEditor(
            segment: selectedSegment,
            onCaptionAdded: () => cubit.addCaption(selectedSegment.id),
            onCaptionRemoved: (captionId) =>
                cubit.removeCaption(selectedSegment.id, captionId),
            onCaptionUpdated: (captionId, start, end, text) {
              cubit.updateCaption(
                selectedSegment.id,
                captionId,
                start: start,
                end: end,
                text: text,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({required this.duration, required this.onChanged});

  final Duration duration;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Duration'),
            const Spacer(),
            Text(_formatDuration(duration)),
          ],
        ),
        Slider(
          min: 5,
          max: 120,
          divisions: 23,
          value: duration.inSeconds.toDouble().clamp(5, 120),
          label: '${duration.inSeconds}s',
          onChanged: (value) => onChanged(Duration(seconds: value.round())),
        ),
      ],
    );
  }
}

class _TransitionSelector extends StatelessWidget {
  const _TransitionSelector({
    required this.segment,
    required this.onChanged,
    required this.onDurationChanged,
  });

  final TimelineSegment segment;
  final ValueChanged<SegmentTransitionType> onChanged;
  final ValueChanged<Duration> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transition', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<SegmentTransitionType>(
                value: segment.transition,
                decoration: const InputDecoration(labelText: 'Type'),
                onChanged: (transition) {
                  if (transition != null) {
                    onChanged(transition);
                  }
                },
                items: SegmentTransitionType.values
                    .map(
                      (transition) => DropdownMenuItem(
                        value: transition,
                        child: Text(transition.label),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: segment.transitionDuration.inMilliseconds,
                decoration: const InputDecoration(labelText: 'Duration (ms)'),
                onChanged: (value) {
                  if (value != null) {
                    onDurationChanged(Duration(milliseconds: value));
                  }
                },
                items: const [200, 350, 500, 750, 1000]
                    .map(
                      (ms) => DropdownMenuItem(value: ms, child: Text('$ms')),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverlayEditor extends StatelessWidget {
  const _OverlayEditor({
    required this.segment,
    required this.onSettingsChanged,
  });

  final TimelineSegment segment;
  final ValueChanged<TextOverlaySettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final settings = segment.overlaySettings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Text Overlay', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: settings.content,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Overlay text'),
          key: ValueKey('${segment.id}-overlay-field'),
          onChanged: (value) =>
              onSettingsChanged(settings.copyWith(content: value)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Bold'),
              selected: settings.isBold,
              onSelected: (selected) =>
                  onSettingsChanged(settings.copyWith(isBold: selected)),
            ),
            FilterChip(
              label: const Text('Italic'),
              selected: settings.isItalic,
              onSelected: (selected) =>
                  onSettingsChanged(settings.copyWith(isItalic: selected)),
            ),
            FilterChip(
              label: const Text('Underline'),
              selected: settings.isUnderline,
              onSelected: (selected) =>
                  onSettingsChanged(settings.copyWith(isUnderline: selected)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Font size'),
            Expanded(
              child: Slider(
                value: settings.fontSize,
                min: 12,
                max: 32,
                divisions: 20,
                label: settings.fontSize.toStringAsFixed(0),
                onChanged: (value) =>
                    onSettingsChanged(settings.copyWith(fontSize: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<OverlayTextAlignment>(
          value: settings.alignment,
          decoration: const InputDecoration(labelText: 'Alignment'),
          onChanged: (value) {
            if (value != null) {
              onSettingsChanged(settings.copyWith(alignment: value));
            }
          },
          items: OverlayTextAlignment.values
              .map(
                (alignment) => DropdownMenuItem(
                  value: alignment,
                  child: Text(alignment.name.toUpperCase()),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<OverlayTextAnimation>(
          value: settings.animation,
          decoration: const InputDecoration(labelText: 'Animation'),
          onChanged: (value) {
            if (value != null) {
              onSettingsChanged(settings.copyWith(animation: value));
            }
          },
          items: OverlayTextAnimation.values
              .map(
                (animation) => DropdownMenuItem(
                  value: animation,
                  child: Text(animation.name),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CaptionEditor extends StatelessWidget {
  const _CaptionEditor({
    required this.segment,
    required this.onCaptionAdded,
    required this.onCaptionRemoved,
    required this.onCaptionUpdated,
  });

  final TimelineSegment segment;
  final VoidCallback onCaptionAdded;
  final ValueChanged<String> onCaptionRemoved;
  final void Function(
    String captionId,
    Duration? start,
    Duration? end,
    String? text,
  )
  onCaptionUpdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Captions', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              tooltip: 'Add caption block',
              onPressed: onCaptionAdded,
              icon: const Icon(Icons.add_outlined),
            ),
          ],
        ),
        ...segment.captions.map(
          (caption) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Caption ${segment.captions.indexOf(caption) + 1}'),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove caption',
                        onPressed: () => onCaptionRemoved(caption.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _CaptionDurationField(
                          fieldKey: ValueKey('${caption.id}-start'),
                          label: 'Start',
                          initialSeconds: caption.start.inSeconds,
                          onChanged: (value) => onCaptionUpdated(
                            caption.id,
                            Duration(seconds: value),
                            null,
                            null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CaptionDurationField(
                          fieldKey: ValueKey('${caption.id}-end'),
                          label: 'End',
                          initialSeconds: caption.end.inSeconds,
                          onChanged: (value) => onCaptionUpdated(
                            caption.id,
                            null,
                            Duration(seconds: value),
                            null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey('${caption.id}-text-field'),
                    initialValue: caption.text,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Caption text',
                    ),
                    onChanged: (value) =>
                        onCaptionUpdated(caption.id, null, null, value),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (segment.captions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Add captions to provide context for your viewers.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

class _CaptionDurationField extends StatelessWidget {
  const _CaptionDurationField({
    required this.label,
    required this.initialSeconds,
    required this.onChanged,
    this.fieldKey,
  });

  final String label;
  final int initialSeconds;
  final ValueChanged<int> onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      initialValue: initialSeconds.toString(),
      decoration: InputDecoration(labelText: label, suffixText: 's'),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.state});

  final TimelineEditorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TimelineEditorCubit>();
    final timelineLength = state.totalTimelineDuration.inSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Play',
                onPressed: () =>
                    cubit.updatePlaybackStatus(TimelinePlaybackStatus.playing),
                icon: const Icon(Icons.play_arrow),
              ),
              IconButton(
                tooltip: 'Pause',
                onPressed: () =>
                    cubit.updatePlaybackStatus(TimelinePlaybackStatus.paused),
                icon: const Icon(Icons.pause),
              ),
              IconButton(
                tooltip: 'Stop',
                onPressed: () =>
                    cubit.updatePlaybackStatus(TimelinePlaybackStatus.stopped),
                icon: const Icon(Icons.stop),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: state.currentPosition.inSeconds.toDouble().clamp(
                    0,
                    timelineLength.toDouble(),
                  ),
                  onChanged: timelineLength == 0
                      ? null
                      : (value) => cubit.updateCurrentPosition(
                          Duration(seconds: value.floor()),
                        ),
                  min: 0,
                  max: timelineLength.toDouble().clamp(1, double.infinity),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDuration(state.currentPosition)} / ${_formatDuration(state.totalTimelineDuration)}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.zoom_in_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: state.zoomLevel,
                  min: 0.5,
                  max: 3,
                  divisions: 10,
                  label: '${(state.zoomLevel * 100).round()}%',
                  onChanged: cubit.updateZoomLevel,
                ),
              ),
              const SizedBox(width: 8),
              Text('Zoom ${(state.zoomLevel * 100).round()}%'),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
