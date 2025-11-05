import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global application BLoC
/// Manages app-level state such as:
/// - App initialization status
/// - Network connectivity
/// - Global loading states
/// - App-wide notifications

// Events
abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

class AppInitialized extends AppEvent {
  const AppInitialized();
}

class AppNetworkStatusChanged extends AppEvent {
  final bool isOnline;

  const AppNetworkStatusChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

// States
abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

class AppInitial extends AppState {
  const AppInitial();
}

class AppReady extends AppState {
  final bool isOnline;

  const AppReady({this.isOnline = true});

  @override
  List<Object?> get props => [isOnline];
}

// BLoC
class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppInitial()) {
    on<AppInitialized>(_onInitialized);
    on<AppNetworkStatusChanged>(_onNetworkStatusChanged);
  }

  void _onInitialized(AppInitialized event, Emitter<AppState> emit) {
    emit(const AppReady(isOnline: true));
  }

  void _onNetworkStatusChanged(
    AppNetworkStatusChanged event,
    Emitter<AppState> emit,
  ) {
    if (state is AppReady) {
      emit(AppReady(isOnline: event.isOnline));
    }
  }
}
