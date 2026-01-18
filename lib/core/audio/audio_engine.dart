import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'platform_channels.dart';
import 'playback_queue.dart';
import '../models/song.dart';

enum PlaybackState {
  idle,
  loading,
  ready,
  playing,
  paused,
  stopped,
  error,
}

class PlaybackStateModel {
  final PlaybackState state;
  final Song? currentSong;
  final int positionMs;
  final int durationMs;
  final double volume;
  final String? error;

  const PlaybackStateModel({
    required this.state,
    this.currentSong,
    this.positionMs = 0,
    this.durationMs = 0,
    this.volume = 1.0,
    this.error,
  });

  PlaybackStateModel copyWith({
    PlaybackState? state,
    Song? currentSong,
    int? positionMs,
    int? durationMs,
    double? volume,
    String? error,
  }) {
    return PlaybackStateModel(
      state: state ?? this.state,
      currentSong: currentSong ?? this.currentSong,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      volume: volume ?? this.volume,
      error: error ?? this.error,
    );
  }
}

class AudioEngine {
  final _playbackStateController = StreamController<PlaybackStateModel>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  PlaybackStateModel _currentState = const PlaybackStateModel(state: PlaybackState.idle);
  final PlaybackQueue _queue = PlaybackQueue();
  StreamSubscription<PlaybackStateModel>? _playbackEndSubscription;

  AudioEngine() {
    _setupEventListeners();
    _setupQueueListeners();
  }
  
  PlaybackQueue get queue => _queue;

  void _setupEventListeners() {
    _eventSubscription = AudioPlatformChannels.playbackEvents.listen((event) {
      final type = event['type'] as String?;
      
      switch (type) {
        case 'playbackState':
          final stateStr = event['state'] as String?;
          final newState = _parsePlaybackState(stateStr);
          _updateState(_currentState.copyWith(state: newState));
          
          // Handle track end
          if (newState == PlaybackState.stopped && _currentState.currentSong != null) {
            _handleTrackEnd();
          }
          break;
        case 'position':
          final positionMs = event['positionMs'] as int? ?? 0;
          final durationMs = event['durationMs'] as int? ?? 0;
          _updateState(_currentState.copyWith(
            positionMs: positionMs,
            durationMs: durationMs,
          ));
          break;
        case 'error':
          final error = event['error'] as String?;
          _updateState(_currentState.copyWith(
            state: PlaybackState.error,
            error: error,
          ));
          break;
      }
    });
  }
  
  void _setupQueueListeners() {
    // Listen for playback end to auto-advance queue
    _playbackEndSubscription = playbackStateStream.listen((state) {
      // Track end handling is done in _handleTrackEnd
    });
  }
  
  void _handleTrackEnd() {
    // Auto-advance to next track if available
    if (_queue.hasNext) {
      final nextTrack = _queue.next();
      if (nextTrack != null) {
        play(nextTrack);
      }
    } else if (_queue.repeatMode == RepeatMode.all && _queue.tracks.isNotEmpty) {
      // Repeat all: go to first track
      _queue.setCurrentIndex(0);
      final firstTrack = _queue.currentTrack;
      if (firstTrack != null) {
        play(firstTrack);
      }
    } else if (_queue.repeatMode == RepeatMode.one && _queue.currentTrack != null) {
      // Repeat one: replay current track
      play(_queue.currentTrack!);
    }
  }

  PlaybackState _parsePlaybackState(String? stateStr) {
    switch (stateStr) {
      case 'playing':
        return PlaybackState.playing;
      case 'paused':
        return PlaybackState.paused;
      case 'ready':
        return PlaybackState.ready;
      case 'buffering':
        return PlaybackState.loading;
      case 'ended':
        return PlaybackState.stopped;
      case 'idle':
        return PlaybackState.idle;
      default:
        return PlaybackState.idle;
    }
  }

  void _updateState(PlaybackStateModel newState) {
    _currentState = newState;
    _playbackStateController.add(newState);
  }

  Stream<PlaybackStateModel> get playbackStateStream => _playbackStateController.stream;
  PlaybackStateModel get currentState => _currentState;

  Future<void> play(Song song) async {
    // Update queue if needed
    if (!_queue.tracks.contains(song)) {
      _queue.add(song);
    }
    _queue.setCurrentIndex(_queue.tracks.indexOf(song));
    
    _updateState(_currentState.copyWith(
      state: PlaybackState.loading,
      currentSong: song,
    ));
    
    // If queue has multiple tracks, use gapless playback
    if (_queue.length > 1) {
      final uris = _queue.tracks.map((s) => s.uri).toList();
      final currentIndex = _queue.currentIndex;
      await AudioPlatformChannels.playQueue(uris, startIndex: currentIndex);
    } else {
      await AudioPlatformChannels.play(song.uri);
    }
  }
  
  /// Play song from queue at index
  Future<void> playFromQueue(int index) async {
    if (index >= 0 && index < _queue.tracks.length) {
      _queue.setCurrentIndex(index);
      final song = _queue.tracks[index];
      await play(song);
    }
  }
  
  /// Play next track in queue
  Future<void> next() async {
    if (_queue.hasNext) {
      final nextTrack = _queue.next();
      if (nextTrack != null) {
        await play(nextTrack);
      }
    } else if (_queue.repeatMode == RepeatMode.all && _queue.tracks.isNotEmpty) {
      _queue.setCurrentIndex(0);
      final firstTrack = _queue.currentTrack;
      if (firstTrack != null) {
        await play(firstTrack);
      }
    }
  }
  
  /// Play previous track in queue
  Future<void> previous() async {
    if (_queue.hasPrevious) {
      final prevTrack = _queue.previous();
      if (prevTrack != null) {
        await play(prevTrack);
      }
    } else if (_queue.repeatMode == RepeatMode.all && _queue.tracks.isNotEmpty) {
      _queue.setCurrentIndex(_queue.tracks.length - 1);
      final lastTrack = _queue.currentTrack;
      if (lastTrack != null) {
        await play(lastTrack);
      }
    }
  }
  
  /// Set shuffle mode
  void setShuffle(bool enabled) {
    _queue.setShuffle(enabled);
  }
  
  /// Set repeat mode
  void setRepeat(RepeatMode mode) {
    _queue.setRepeat(mode);
  }

  Future<void> pause() async {
    await AudioPlatformChannels.pause();
  }

  Future<void> resume() async {
    await AudioPlatformChannels.resume();
  }

  Future<void> seek(int positionMs) async {
    await AudioPlatformChannels.seek(positionMs);
  }

  Future<void> setVolume(double volume) async {
    await AudioPlatformChannels.setVolume(volume);
    _updateState(_currentState.copyWith(volume: volume));
  }

  void dispose() {
    _eventSubscription?.cancel();
    _playbackEndSubscription?.cancel();
    _playbackStateController.close();
  }
}

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = AudioEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
});

final playbackStateProvider = StreamProvider<PlaybackStateModel>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.playbackStateStream;
});
