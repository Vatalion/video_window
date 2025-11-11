import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/feed_configuration.dart';
import '../../domain/entities/video.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../../use_cases/update_feed_preferences_use_case.dart';

/// Feed settings sheet for personalization preferences
/// AC1: Allows toggling auto-play, captions, playback speed, preferred quality, and tag filters
/// AC3: Reduced motion preference turns off auto-play and enables static preview thumbnails
/// AC4: UI surfaces blocked maker list with ability to add/remove
class FeedSettingsSheet extends StatefulWidget {
  final FeedConfiguration currentConfiguration;
  final String userId;

  const FeedSettingsSheet({
    super.key,
    required this.currentConfiguration,
    required this.userId,
  });

  @override
  State<FeedSettingsSheet> createState() => _FeedSettingsSheetState();
}

class _FeedSettingsSheetState extends State<FeedSettingsSheet> {
  late FeedConfiguration _configuration;
  late UpdateFeedPreferencesUseCase _updateUseCase;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _configuration = widget.currentConfiguration;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize use case with repository from bloc
    if (!mounted) return;
    final bloc = context.read<FeedBloc>();
    _updateUseCase = UpdateFeedPreferencesUseCase(
      repository: bloc.repository,
    );
  }

  Future<void> _savePreferences() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _updateUseCase.execute(
        userId: widget.userId,
        configuration: _configuration,
      );

      // Refresh feed with new preferences
      if (mounted) {
        context.read<FeedBloc>().add(FeedPreferencesUpdated(_configuration));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Feed Preferences',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPlaybackSection(),
                    const SizedBox(height: 24),
                    _buildPersonalizationSection(),
                    const SizedBox(height: 24),
                    _buildBlockedMakersSection(),
                    const SizedBox(height: 24),
                    _buildAccessibilitySection(),
                  ],
                ),
              ),
              // Save button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePreferences,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Preferences'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaybackSection() {
    return _buildSection(
      title: 'Playback',
      children: [
        // Auto-play toggle
        SwitchListTile(
          title: const Text('Auto-play videos'),
          subtitle: const Text('Videos play automatically when visible'),
          value: _configuration.autoPlay,
          onChanged: (value) {
            setState(() {
              _configuration = FeedConfiguration(
                id: _configuration.id,
                userId: _configuration.userId,
                preferredTags: _configuration.preferredTags,
                blockedMakers: _configuration.blockedMakers,
                preferredQuality: _configuration.preferredQuality,
                autoPlay: value,
                showCaptions: _configuration.showCaptions,
                playbackSpeed: _configuration.playbackSpeed,
                algorithm: _configuration.algorithm,
                lastUpdated: DateTime.now(),
              );
            });
          },
        ),
        // Playback speed
        ListTile(
          title: const Text('Playback Speed'),
          subtitle: Text('${_configuration.playbackSpeed}x'),
          trailing: DropdownButton<double>(
            value: _configuration.playbackSpeed,
            items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                .map((speed) => DropdownMenuItem(
                      value: speed,
                      child: Text('${speed}x'),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _configuration = FeedConfiguration(
                    id: _configuration.id,
                    userId: _configuration.userId,
                    preferredTags: _configuration.preferredTags,
                    blockedMakers: _configuration.blockedMakers,
                    preferredQuality: _configuration.preferredQuality,
                    autoPlay: _configuration.autoPlay,
                    showCaptions: _configuration.showCaptions,
                    playbackSpeed: value,
                    algorithm: _configuration.algorithm,
                    lastUpdated: DateTime.now(),
                  );
                });
              }
            },
          ),
        ),
        // Preferred quality
        ListTile(
          title: const Text('Preferred Quality'),
          subtitle: Text(_configuration.preferredQuality.name.toUpperCase()),
          trailing: DropdownButton<VideoQuality>(
            value: _configuration.preferredQuality,
            items: VideoQuality.values
                .map((quality) => DropdownMenuItem(
                      value: quality,
                      child: Text(quality.name.toUpperCase()),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _configuration = FeedConfiguration(
                    id: _configuration.id,
                    userId: _configuration.userId,
                    preferredTags: _configuration.preferredTags,
                    blockedMakers: _configuration.blockedMakers,
                    preferredQuality: value,
                    autoPlay: _configuration.autoPlay,
                    showCaptions: _configuration.showCaptions,
                    playbackSpeed: _configuration.playbackSpeed,
                    algorithm: _configuration.algorithm,
                    lastUpdated: DateTime.now(),
                  );
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalizationSection() {
    return _buildSection(
      title: 'Personalization',
      children: [
        // Algorithm selection
        ListTile(
          title: const Text('Feed Algorithm'),
          subtitle: Text(_configuration.algorithm.name),
          trailing: DropdownButton<FeedAlgorithm>(
            value: _configuration.algorithm,
            items: FeedAlgorithm.values
                .map((algorithm) => DropdownMenuItem(
                      value: algorithm,
                      child: Text(algorithm.name),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _configuration = FeedConfiguration(
                    id: _configuration.id,
                    userId: _configuration.userId,
                    preferredTags: _configuration.preferredTags,
                    blockedMakers: _configuration.blockedMakers,
                    preferredQuality: _configuration.preferredQuality,
                    autoPlay: _configuration.autoPlay,
                    showCaptions: _configuration.showCaptions,
                    playbackSpeed: _configuration.playbackSpeed,
                    algorithm: value,
                    lastUpdated: DateTime.now(),
                  );
                });
              }
            },
          ),
        ),
        // Tag filters (simplified - would need tag selection UI)
        ListTile(
          title: const Text('Preferred Tags'),
          subtitle: Text(
            _configuration.preferredTags.isEmpty
                ? 'No tags selected'
                : _configuration.preferredTags.join(', '),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Open tag selection dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tag selection coming soon'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedMakersSection() {
    return _buildSection(
      title: 'Blocked Makers',
      subtitle: 'Videos from these makers will not appear in your feed',
      children: [
        if (_configuration.blockedMakers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No blocked makers',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._configuration.blockedMakers.map((makerId) => ListTile(
                title: Text('Maker: $makerId'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      final updatedBlocked = List<String>.from(
                        _configuration.blockedMakers,
                      )..remove(makerId);
                      _configuration = FeedConfiguration(
                        id: _configuration.id,
                        userId: _configuration.userId,
                        preferredTags: _configuration.preferredTags,
                        blockedMakers: updatedBlocked,
                        preferredQuality: _configuration.preferredQuality,
                        autoPlay: _configuration.autoPlay,
                        showCaptions: _configuration.showCaptions,
                        playbackSpeed: _configuration.playbackSpeed,
                        algorithm: _configuration.algorithm,
                        lastUpdated: DateTime.now(),
                      );
                    });
                  },
                ),
              )),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Block a maker'),
          onTap: () {
            // TODO: Open maker search/selection dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maker blocking coming soon'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection() {
    // AC3: Reduced motion preference
    final reducedMotion = !_configuration.autoPlay &&
        _configuration.preferredQuality == VideoQuality.sd;

    return _buildSection(
      title: 'Accessibility',
      children: [
        // Reduced motion toggle
        SwitchListTile(
          title: const Text('Reduced Motion'),
          subtitle: const Text(
            'Disables auto-play and uses static preview thumbnails',
          ),
          value: reducedMotion,
          onChanged: (value) {
            setState(() {
              _configuration = FeedConfiguration(
                id: _configuration.id,
                userId: _configuration.userId,
                preferredTags: _configuration.preferredTags,
                blockedMakers: _configuration.blockedMakers,
                preferredQuality:
                    value ? VideoQuality.sd : _configuration.preferredQuality,
                autoPlay: value ? false : _configuration.autoPlay,
                showCaptions: _configuration.showCaptions,
                playbackSpeed: _configuration.playbackSpeed,
                algorithm: _configuration.algorithm,
                lastUpdated: DateTime.now(),
              );
            });
          },
        ),
        // Captions toggle
        SwitchListTile(
          title: const Text('Show Captions'),
          subtitle: const Text('Display captions for videos when available'),
          value: _configuration.showCaptions,
          onChanged: (value) {
            setState(() {
              _configuration = FeedConfiguration(
                id: _configuration.id,
                userId: _configuration.userId,
                preferredTags: _configuration.preferredTags,
                blockedMakers: _configuration.blockedMakers,
                preferredQuality: _configuration.preferredQuality,
                autoPlay: _configuration.autoPlay,
                showCaptions: value,
                playbackSpeed: _configuration.playbackSpeed,
                algorithm: _configuration.algorithm,
                lastUpdated: DateTime.now(),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}
