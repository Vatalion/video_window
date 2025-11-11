import 'package:flutter/material.dart';

/// Section navigation widget with smooth scrolling
/// AC1: Section navigation with active indicators
class SectionNavigation extends StatelessWidget {
  final List<String> sections;
  final String activeSection;
  final Function(String) onSectionTap;

  const SectionNavigation({
    super.key,
    required this.sections,
    required this.activeSection,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          final isActive = section == activeSection;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _SectionTab(
              section: section,
              isActive: isActive,
              onTap: () => onSectionTap(section),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  final String section;
  final bool isActive;
  final VoidCallback onTap;

  const _SectionTab({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          _getSectionTitle(section),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getSectionTitle(String section) {
    switch (section) {
      case 'overview':
        return 'Overview';
      case 'process':
        return 'Process';
      case 'materials':
        return 'Materials';
      case 'notes':
        return 'Notes';
      case 'location':
        return 'Location';
      default:
        return section;
    }
  }
}
