import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/data/services/capabilities/capability_service.dart';
import 'package:video_window_client/video_window_client.dart';
import 'capability_center_event.dart';
import 'capability_center_state.dart';

/// BLoC for managing capability center state
///
/// Implements AC1: Fetches status on init, handles poll refreshes, emits analytics
/// AC2: Handles inline capability requests from various entry points
class CapabilityCenterBloc
    extends Bloc<CapabilityCenterEvent, CapabilityCenterState> {
  final CapabilityService _capabilityService;
  StreamSubscription<dynamic>? _pollingSubscription;

  CapabilityCenterBloc(this._capabilityService)
      : super(const CapabilityCenterInitial()) {
    on<CapabilityCenterLoadRequested>(_onLoadRequested);
    on<CapabilityCenterRequestSubmitted>(_onRequestSubmitted);
    on<CapabilityCenterRefreshRequested>(_onRefreshRequested);
    on<CapabilityCenterPollingStarted>(_onPollingStarted);
    on<CapabilityCenterPollingStopped>(_onPollingStopped);
  }

  /// Handle load requested event
  Future<void> _onLoadRequested(
    CapabilityCenterLoadRequested event,
    Emitter<CapabilityCenterState> emit,
  ) async {
    emit(const CapabilityCenterLoading());

    try {
      final status = await _capabilityService.getStatus(event.userId);
      emit(_mapStatusToState(status, event.userId));
    } catch (e) {
      emit(const CapabilityCenterError(
        'Failed to load capability status',
        errorCode: 'LOAD_ERROR',
      ));
    }
  }

  /// Handle capability request submission
  ///
  /// AC2: Inline prompts submit requests with context
  /// AC3: Calls service with metadata, handles idempotent retries
  /// AC5: Analytics event emitted by service layer
  Future<void> _onRequestSubmitted(
    CapabilityCenterRequestSubmitted event,
    Emitter<CapabilityCenterState> emit,
  ) async {
    emit(CapabilityCenterRequesting(event.capability));

    try {
      final status = await _capabilityService.requestCapability(
        userId: event.userId,
        capability: event.capability,
        entryPoint: event.entryPoint,
        additionalContext: event.context,
      );

      emit(_mapStatusToState(status, event.userId));
    } catch (e) {
      emit(const CapabilityCenterError(
        'Failed to request capability',
        errorCode: 'REQUEST_ERROR',
      ));
    }
  }

  /// Handle refresh requested event
  Future<void> _onRefreshRequested(
    CapabilityCenterRefreshRequested event,
    Emitter<CapabilityCenterState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;

    try {
      final status = await _capabilityService.getStatus(event.userId);
      emit(_mapStatusToState(
        status,
        event.userId,
        isPolling: currentState is CapabilityCenterLoaded
            ? currentState.isPolling
            : false,
      ));
    } catch (e) {
      // Keep current state on refresh error
      if (currentState is CapabilityCenterLoaded) {
        // Silent failure on background refresh
        return;
      }
      emit(const CapabilityCenterError(
        'Failed to refresh capability status',
        errorCode: 'REFRESH_ERROR',
      ));
    }
  }

  /// Start polling for status updates
  Future<void> _onPollingStarted(
    CapabilityCenterPollingStarted event,
    Emitter<CapabilityCenterState> emit,
  ) async {
    // Cancel existing subscription
    await _pollingSubscription?.cancel();

    // Start new polling subscription
    _pollingSubscription = _capabilityService
        .subscribeToUpdates(
      event.userId,
      initialInterval: const Duration(seconds: 5),
      maxInterval: const Duration(minutes: 5),
    )
        .listen(
      (status) {
        add(CapabilityCenterRefreshRequested(event.userId));
      },
      onError: (error) {
        // Log error but continue polling
      },
    );

    // Update state to indicate polling is active
    if (state is CapabilityCenterLoaded) {
      emit((state as CapabilityCenterLoaded).copyWith(isPolling: true));
    }
  }

  /// Stop polling
  Future<void> _onPollingStopped(
    CapabilityCenterPollingStopped event,
    Emitter<CapabilityCenterState> emit,
  ) async {
    await _pollingSubscription?.cancel();
    _pollingSubscription = null;

    if (state is CapabilityCenterLoaded) {
      emit((state as CapabilityCenterLoaded).copyWith(isPolling: false));
    }
  }

  /// Map API response to state
  ///
  /// AC3: Maps server response to state, including capability flags and timestamps
  /// Story 2-2 Fix: Now uses actual CapabilityStatusResponse instead of hardcoded values
  CapabilityCenterLoaded _mapStatusToState(
    dynamic status,
    int userId, {
    bool isPolling = false,
  }) {
    // Cast to typed response
    final typedStatus = status as CapabilityStatusResponse;

    return CapabilityCenterLoaded(
      userId: userId,
      canPublish: typedStatus.canPublish,
      canCollectPayments: typedStatus.canCollectPayments,
      canFulfillOrders: typedStatus.canFulfillOrders,
      identityVerifiedAt: typedStatus.identityVerifiedAt,
      payoutConfiguredAt: typedStatus.payoutConfiguredAt,
      fulfillmentEnabledAt: typedStatus.fulfillmentEnabledAt,
      reviewState: typedStatus.reviewState.name,
      blockers: typedStatus.blockers,
      isPolling: isPolling,
    );
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }
}
