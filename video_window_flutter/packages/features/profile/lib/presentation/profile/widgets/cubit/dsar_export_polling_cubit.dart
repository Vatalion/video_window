import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';

/// Cubit for polling DSAR export status
/// AC2: DSAR export generates downloadable package within 24 hours and surfaces status/progress in UI with polling
abstract class DSARExportPollingState {}

class DSARExportPollingInitial extends DSARExportPollingState {}

class DSARExportPollingInProgress extends DSARExportPollingState {
  final String exportId;
  final String? statusMessage;
  final DateTime? estimatedCompletionAt;

  DSARExportPollingInProgress({
    required this.exportId,
    this.statusMessage,
    this.estimatedCompletionAt,
  });
}

class DSARExportPollingCompleted extends DSARExportPollingState {
  final String downloadUrl;
  final DateTime expiresAt;

  DSARExportPollingCompleted({
    required this.downloadUrl,
    required this.expiresAt,
  });
}

class DSARExportPollingError extends DSARExportPollingState {
  final String errorMessage;

  DSARExportPollingError(this.errorMessage);
}

class DSARExportPollingCubit extends Cubit<DSARExportPollingState> {
  final ProfileBloc _profileBloc;
  Timer? _pollingTimer;
  final String _exportId;

  DSARExportPollingCubit(this._profileBloc)
      : _exportId = '',
        super(DSARExportPollingInitial());

  void startPolling(String exportId) {
    _pollingTimer?.cancel();
    emit(DSARExportPollingInProgress(exportId: exportId));

    // Poll every 5 seconds
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkExportStatus(exportId),
    );

    // Initial check
    _checkExportStatus(exportId);
  }

  Future<void> _checkExportStatus(String exportId) async {
    try {
      // TODO: Call backend API to check export status
      // For now, this is a placeholder
      // final status = await _profileBloc.repository.getDSARExportStatus(exportId);

      // Simulate polling - in real implementation, this would call the backend
      await Future.delayed(const Duration(milliseconds: 500));

      // Check current state from ProfileBloc
      final currentState = _profileBloc.state;
      if (currentState is DSARExportCompleted) {
        _pollingTimer?.cancel();
        emit(DSARExportPollingCompleted(
          downloadUrl: currentState.downloadUrl ?? '',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ));
      } else if (currentState is DSARExportInProgress) {
        emit(DSARExportPollingInProgress(
          exportId: exportId,
          statusMessage: currentState.statusMessage,
          estimatedCompletionAt: currentState.estimatedCompletionAt,
        ));
      } else if (currentState is ProfileError) {
        _pollingTimer?.cancel();
        emit(DSARExportPollingError(currentState.message));
      }
    } catch (e) {
      _pollingTimer?.cancel();
      emit(DSARExportPollingError('Failed to check export status: $e'));
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
