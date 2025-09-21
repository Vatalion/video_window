import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/content_version.dart';
import '../../domain/repositories/content_version_repository.dart';

part 'version_control_event.dart';
part 'version_control_state.dart';

class VersionControlBloc extends Bloc<VersionControlEvent, VersionControlState> {
  final ContentVersionRepository _contentVersionRepository;

  VersionControlBloc({required ContentVersionRepository contentVersionRepository})
      : _contentVersionRepository = contentVersionRepository,
        super(VersionControlInitial()) {
    on<LoadContentVersions>(_onLoadContentVersions);
    on<CompareVersions>(_onCompareVersions);
    on<RestoreContentVersion>(_onRestoreContentVersion);
  }

  Future<void> _onLoadContentVersions(
    LoadContentVersions event,
    Emitted<VersionControlState> emit,
  ) async {
    emit(VersionControlLoading());
    try {
      final versions = await _contentVersionRepository.getContentVersions(event.contentId);
      emit(ContentVersionsLoaded(versions));
    } catch (e) {
      emit(VersionControlError(e.toString()));
    }
  }

  Future<void> _onCompareVersions(
    CompareVersions event,
    Emitted<VersionControlState> emit,
  ) async {
    emit(VersionControlLoading());
    try {
      final comparison = await _contentVersionRepository.compareVersions(
        event.version1Id,
        event.version2Id,
      );
      emit(VersionComparisonLoaded(comparison));
    } catch (e) {
      emit(VersionControlError(e.toString()));
    }
  }

  Future<void> _onRestoreContentVersion(
    RestoreContentVersion event,
    Emitted<VersionControlState> emit,
  ) async {
    emit(VersionControlLoading());
    try {
      final version = await _contentVersionRepository.getContentVersion(event.versionId);
      if (version != null) {
        // In a real implementation, this would restore the content to this version
        // For now, we'll just emit a success state
        emit(ContentVersionRestored(version));
      } else {
        emit(const VersionControlError('Version not found'));
      }
    } catch (e) {
      emit(VersionControlError(e.toString()));
    }
  }
}