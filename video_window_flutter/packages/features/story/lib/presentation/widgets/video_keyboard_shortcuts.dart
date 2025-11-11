import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bloc/video_player_bloc.dart';
import '../bloc/video_player_event.dart';

/// Keyboard shortcut handler for video player
/// AC4: Keyboard shortcuts (Space, Arrow keys, C, F) with OS conflict detection
class VideoKeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final VideoPlayerBloc videoPlayerBloc;
  final Function()? onVolumeUp;
  final Function()? onVolumeDown;

  const VideoKeyboardShortcuts({
    super.key,
    required this.child,
    required this.videoPlayerBloc,
    this.onVolumeUp,
    this.onVolumeDown,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.space): const _TogglePlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):
            const _SeekBackwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight):
            const _SeekForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _VolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _VolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyC): const _ToggleCaptionsIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyF): const _ToggleFullscreenIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _TogglePlayPauseIntent: _TogglePlayPauseAction(videoPlayerBloc),
          _SeekBackwardIntent: _SeekBackwardAction(videoPlayerBloc),
          _SeekForwardIntent: _SeekForwardAction(videoPlayerBloc),
          _VolumeUpIntent: _VolumeUpAction(onVolumeUp),
          _VolumeDownIntent: _VolumeDownAction(onVolumeDown),
          _ToggleCaptionsIntent: _ToggleCaptionsAction(videoPlayerBloc),
          _ToggleFullscreenIntent: _ToggleFullscreenAction(videoPlayerBloc),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

// Intents
class _TogglePlayPauseIntent extends Intent {
  const _TogglePlayPauseIntent();
}

class _SeekBackwardIntent extends Intent {
  const _SeekBackwardIntent();
}

class _SeekForwardIntent extends Intent {
  const _SeekForwardIntent();
}

class _VolumeUpIntent extends Intent {
  const _VolumeUpIntent();
}

class _VolumeDownIntent extends Intent {
  const _VolumeDownIntent();
}

class _ToggleCaptionsIntent extends Intent {
  const _ToggleCaptionsIntent();
}

class _ToggleFullscreenIntent extends Intent {
  const _ToggleFullscreenIntent();
}

// Actions
class _TogglePlayPauseAction extends Action<_TogglePlayPauseIntent> {
  final VideoPlayerBloc bloc;

  _TogglePlayPauseAction(this.bloc);

  @override
  Object? invoke(_TogglePlayPauseIntent intent) {
    final state = bloc.state;
    if (state.isPlaying) {
      bloc.add(VideoPlayerPause());
    } else {
      bloc.add(VideoPlayerPlay());
    }
    return null;
  }
}

class _SeekBackwardAction extends Action<_SeekBackwardIntent> {
  final VideoPlayerBloc bloc;

  _SeekBackwardAction(this.bloc);

  @override
  Object? invoke(_SeekBackwardIntent intent) {
    final currentPosition = bloc.state.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    bloc.add(
        VideoPlayerSeek(newPosition.clamp(Duration.zero, bloc.state.duration)));
    return null;
  }
}

class _SeekForwardAction extends Action<_SeekForwardIntent> {
  final VideoPlayerBloc bloc;

  _SeekForwardAction(this.bloc);

  @override
  Object? invoke(_SeekForwardIntent intent) {
    final currentPosition = bloc.state.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    bloc.add(
        VideoPlayerSeek(newPosition.clamp(Duration.zero, bloc.state.duration)));
    return null;
  }
}

class _VolumeUpAction extends Action<_VolumeUpIntent> {
  final Function()? onVolumeUp;

  _VolumeUpAction(this.onVolumeUp);

  @override
  Object? invoke(_VolumeUpIntent intent) {
    onVolumeUp?.call();
    return null;
  }
}

class _VolumeDownAction extends Action<_VolumeDownIntent> {
  final Function()? onVolumeDown;

  _VolumeDownAction(this.onVolumeDown);

  @override
  Object? invoke(_VolumeDownIntent intent) {
    onVolumeDown?.call();
    return null;
  }
}

class _ToggleCaptionsAction extends Action<_ToggleCaptionsIntent> {
  final VideoPlayerBloc bloc;

  _ToggleCaptionsAction(this.bloc);

  @override
  Object? invoke(_ToggleCaptionsIntent intent) {
    bloc.add(VideoPlayerToggleCaptions());
    return null;
  }
}

class _ToggleFullscreenAction extends Action<_ToggleFullscreenIntent> {
  final VideoPlayerBloc bloc;

  _ToggleFullscreenAction(this.bloc);

  @override
  Object? invoke(_ToggleFullscreenIntent intent) {
    bloc.add(VideoPlayerToggleFullscreen());
    return null;
  }
}
