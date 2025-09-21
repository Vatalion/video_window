part of 'version_control_bloc.dart';

abstract class VersionControlState extends Equatable {
  const VersionControlState();

  @override
  List<Object> get props => [];
}

class VersionControlInitial extends VersionControlState {}

class VersionControlLoading extends VersionControlState {}

class ContentVersionsLoaded extends VersionControlState {
  final List<ContentVersion> versions;

  const ContentVersionsLoaded(this.versions);

  @override
  List<Object> get props => [versions];
}

class VersionComparisonLoaded extends VersionControlState {
  final ContentVersionComparison comparison;

  const VersionComparisonLoaded(this.comparison);

  @override
  List<Object> get props => [comparison];
}

class ContentVersionRestored extends VersionControlState {
  final ContentVersion version;

  const ContentVersionRestored(this.version);

  @override
  List<Object> get props => [version];
}

class VersionControlError extends VersionControlState {
  final String message;

  const VersionControlError(this.message);

  @override
  List<Object> get props => [message];
}