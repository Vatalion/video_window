part of 'version_control_bloc.dart';

abstract class VersionControlEvent extends Equatable {
  const VersionControlEvent();

  @override
  List<Object> get props => [];
}

class LoadContentVersions extends VersionControlEvent {
  final String contentId;

  const LoadContentVersions({required this.contentId});

  @override
  List<Object> get props => [contentId];
}

class CompareVersions extends VersionControlEvent {
  final String version1Id;
  final String version2Id;

  const CompareVersions({
    required this.version1Id,
    required this.version2Id,
  });

  @override
  List<Object> get props => [version1Id, version2Id];
}

class RestoreContentVersion extends VersionControlEvent {
  final String contentId;
  final String versionId;

  const RestoreContentVersion({
    required this.contentId,
    required this.versionId,
  });

  @override
  List<Object> get props => [contentId, versionId];
}