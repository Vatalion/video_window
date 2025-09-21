import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/content_version.dart';
import '../bloc/version_control_bloc.dart';

class VersionControlScreen extends StatelessWidget {
  final String contentId;

  const VersionControlScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Version Control'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<VersionControlBloc, VersionControlState>(
        builder: (context, state) {
          if (state is VersionControlLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ContentVersionsLoaded) {
            if (state.versions.isEmpty) {
              return const Center(
                child: Text('No versions found for this content'),
              );
            }

            // Sort versions by version number (newest first)
            final sortedVersions = List<ContentVersion>.from(state.versions)
              ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));

            return Column(
              children: [
                // Version list
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedVersions.length,
                    itemBuilder: (context, index) {
                      final version = sortedVersions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text('Version ${version.versionNumber}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(version.title),
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${version.createdAt}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (version.changesSummary != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  version.changesSummary!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.compare),
                            onPressed: () {
                              // Compare with previous version
                              if (index < sortedVersions.length - 1) {
                                context.read<VersionControlBloc>().add(
                                      CompareVersions(
                                        version1Id: version.id,
                                        version2Id: sortedVersions[index + 1].id,
                                      ),
                                    );
                              }
                            },
                          ),
                          onTap: () {
                            // View version details
                            _showVersionDetails(context, version);
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                // Restore button
                if (sortedVersions.length > 1) // Only show if there are multiple versions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Restore to latest version
                        context.read<VersionControlBloc>().add(
                              RestoreContentVersion(
                                contentId: contentId,
                                versionId: sortedVersions.first.id,
                              ),
                            );
                      },
                      child: const Text('Restore to Latest Version'),
                    ),
                  ),
              ],
            );
          } else if (state is VersionComparisonLoaded) {
            return _buildComparisonView(context, state.comparison);
          } else if (state is VersionControlError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }

          // Load initial data
          context.read<VersionControlBloc>().add(
                LoadContentVersions(contentId: contentId),
              );

          return const Center(
            child: Text('Loading content versions...'),
          );
        },
      ),
    );
  }

  void _showVersionDetails(BuildContext context, ContentVersion version) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version ${version.versionNumber}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Title: ${version.title}'),
              const SizedBox(height: 8),
              Text('Description: ${version.description}'),
              const SizedBox(height: 8),
              Text('Created by: ${version.createdBy}'),
              const SizedBox(height: 8),
              Text('Created at: ${version.createdAt}'),
              if (version.changesSummary != null) ...[
                const SizedBox(height: 8),
                Text('Changes: ${version.changesSummary}'),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restore this version
                  context.read<VersionControlBloc>().add(
                        RestoreContentVersion(
                          contentId: version.contentId,
                          versionId: version.id,
                        ),
                      );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content restored to selected version')),
                  );
                },
                child: const Text('Restore to this Version'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonView(BuildContext context, ContentVersionComparison comparison) {
    return Column(
      children: [
        // Comparison header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Comparing Version ${comparison.version1.versionNumber}'),
              const Text('VS'),
              Text('Version ${comparison.version2.versionNumber}'),
            ],
          ),
        ),
        
        // Differences list
        Expanded(
          child: ListView.builder(
            itemCount: comparison.differences.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(comparison.differences[index]),
                ),
              );
            },
          ),
        ),
        
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  // Go back to version list
                  context.read<VersionControlBloc>().add(
                        LoadContentVersions(contentId: contentId),
                      );
                },
                child: const Text('Back to Versions'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Restore version 1
                  context.read<VersionControlBloc>().add(
                        RestoreContentVersion(
                          contentId: comparison.version1.contentId,
                          versionId: comparison.version1.id,
                        ),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content restored to selected version')),
                  );
                },
                child: Text('Restore to Version ${comparison.version1.versionNumber}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}