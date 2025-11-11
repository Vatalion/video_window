import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/story_bloc.dart';
import '../bloc/story_event.dart';
import '../widgets/story_video_player.dart';
import '../widgets/section_navigation.dart';
import '../widgets/story_overview.dart';
import '../widgets/process_timeline.dart';
import '../widgets/materials_section.dart';
import '../widgets/sticky_cta.dart';

/// Story detail page with video carousel and section navigation
/// AC1: Complete story page layout with video carousel, section navigation, and sticky CTA
class StoryDetailPage extends StatefulWidget {
  final String storyId;
  final String? source;

  const StoryDetailPage({
    super.key,
    required this.storyId,
    this.source,
  });

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    _initializeSectionKeys();
    context.read<StoryBloc>().add(
          StoryLoadRequested(
            storyId: widget.storyId,
            source: widget.source ?? 'direct',
          ),
        );
  }

  void _initializeSectionKeys() {
    _sectionKeys['overview'] = GlobalKey();
    _sectionKeys['process'] = GlobalKey();
    _sectionKeys['materials'] = GlobalKey();
    _sectionKeys['notes'] = GlobalKey();
    _sectionKeys['location'] = GlobalKey();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(String sectionId) {
    final key = _sectionKeys[sectionId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      context.read<StoryBloc>().add(SectionNavigated(sectionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<StoryBloc, StoryState>(
        builder: (context, state) {
          if (state is StoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () {
                      context.read<StoryBloc>().add(
                            StoryLoadRequested(
                              storyId: widget.storyId,
                              source: widget.source ?? 'direct',
                            ),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is StoryLoaded) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero video section
                SliverToBoxAdapter(
                  child: StoryVideoPlayer(
                    videoUrl: state.story.heroVideo.url,
                    storyId: state.story.id,
                  ),
                ),

                // Section navigation
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SectionNavigationDelegate(
                    sections: _getAvailableSections(state.story),
                    activeSection: state.activeSection,
                    onSectionTap: _scrollToSection,
                  ),
                ),

                // Story sections
                SliverToBoxAdapter(
                  key: _sectionKeys['overview'],
                  child: StoryOverviewSection(story: state.story),
                ),

                if (state.story.process != null)
                  SliverToBoxAdapter(
                    key: _sectionKeys['process'],
                    child:
                        ProcessTimelineSection(section: state.story.process!),
                  ),

                if (state.story.materials != null)
                  SliverToBoxAdapter(
                    key: _sectionKeys['materials'],
                    child: MaterialsSection(section: state.story.materials!),
                  ),

                // Sticky CTA
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: StickyCTA(
                    storyId: state.story.id,
                    onCTAPressed: () => _scrollToSection('offers'),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<String> _getAvailableSections(StoryLoaded state) {
    final sections = ['overview'];
    if (state.process != null) sections.add('process');
    if (state.materials != null) sections.add('materials');
    if (state.notes != null) sections.add('notes');
    if (state.location != null) sections.add('location');
    return sections;
  }
}

/// Delegate for section navigation header
class SectionNavigationDelegate extends SliverPersistentHeaderDelegate {
  final List<String> sections;
  final String activeSection;
  final Function(String) onSectionTap;

  SectionNavigationDelegate({
    required this.sections,
    required this.activeSection,
    required this.onSectionTap,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SectionNavigation(
        sections: sections,
        activeSection: activeSection,
        onSectionTap: onSectionTap,
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(SectionNavigationDelegate oldDelegate) {
    return oldDelegate.activeSection != activeSection ||
        oldDelegate.sections != sections;
  }
}
