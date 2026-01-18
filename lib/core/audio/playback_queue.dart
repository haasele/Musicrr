import '../models/song.dart';

enum RepeatMode {
  none,
  one,
  all,
}

class PlaybackQueue {
  final List<Song> _tracks = [];
  int _currentIndex = -1;
  bool _shuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.none;
  List<int> _originalOrder = [];

  List<Song> get tracks => List.unmodifiable(_tracks);
  int get currentIndex => _currentIndex;
  Song? get currentTrack => _currentIndex >= 0 && _currentIndex < _tracks.length 
      ? _tracks[_currentIndex] 
      : null;
  bool get shuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  int get length => _tracks.length;
  bool get isEmpty => _tracks.isEmpty;
  bool get hasNext => _hasNextTrack();
  bool get hasPrevious => _hasPreviousTrack();

  void add(Song song) {
    _tracks.add(song);
    if (_currentIndex == -1) {
      _currentIndex = 0;
    }
  }

  void addAll(List<Song> songs) {
    _tracks.addAll(songs);
    if (_currentIndex == -1 && _tracks.isNotEmpty) {
      _currentIndex = 0;
    }
  }

  void insert(int index, Song song) {
    _tracks.insert(index, song);
    if (_currentIndex == -1) {
      _currentIndex = 0;
    } else if (index <= _currentIndex) {
      _currentIndex++;
    }
  }

  void removeAt(int index) {
    if (index < 0 || index >= _tracks.length) return;
    
    _tracks.removeAt(index);
    
    if (_tracks.isEmpty) {
      _currentIndex = -1;
    } else if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_currentIndex >= _tracks.length) {
        _currentIndex = _tracks.length - 1;
      }
    }
  }

  void clear() {
    _tracks.clear();
    _currentIndex = -1;
    _originalOrder.clear();
  }

  void reorder(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= _tracks.length ||
        toIndex < 0 || toIndex >= _tracks.length) {
      return;
    }

    final song = _tracks.removeAt(fromIndex);
    _tracks.insert(toIndex, song);

    // Update current index
    if (fromIndex == _currentIndex) {
      _currentIndex = toIndex;
    } else if (fromIndex < _currentIndex && toIndex >= _currentIndex) {
      _currentIndex--;
    } else if (fromIndex > _currentIndex && toIndex <= _currentIndex) {
      _currentIndex++;
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _tracks.length) {
      _currentIndex = index;
    }
  }

  Song? next() {
    if (!_hasNextTrack()) return null;

    if (_shuffleEnabled) {
      _currentIndex = _getNextShuffledIndex();
    } else {
      _currentIndex++;
    }

    return currentTrack;
  }

  Song? previous() {
    if (!_hasPreviousTrack()) return null;

    if (_shuffleEnabled) {
      _currentIndex = _getPreviousShuffledIndex();
    } else {
      _currentIndex--;
    }

    return currentTrack;
  }

  void setShuffle(bool enabled) {
    if (enabled == _shuffleEnabled) return;

    _shuffleEnabled = enabled;

    if (enabled) {
      // Save original order
      _originalOrder = List.generate(_tracks.length, (i) => i);
      // Shuffle tracks
      _shuffleTracks();
    } else {
      // Restore original order
      _restoreOriginalOrder();
    }
  }

  void setRepeat(RepeatMode mode) {
    _repeatMode = mode;
  }

  bool _hasNextTrack() {
    if (_tracks.isEmpty) return false;
    if (_currentIndex < 0) return true;

    switch (_repeatMode) {
      case RepeatMode.none:
        return _currentIndex < _tracks.length - 1;
      case RepeatMode.one:
        return true;
      case RepeatMode.all:
        return true;
    }
  }

  bool _hasPreviousTrack() {
    if (_tracks.isEmpty) return false;
    if (_currentIndex < 0) return false;

    switch (_repeatMode) {
      case RepeatMode.none:
        return _currentIndex > 0;
      case RepeatMode.one:
        return true;
      case RepeatMode.all:
        return true;
    }
  }

  int _getNextShuffledIndex() {
    if (_tracks.length <= 1) return 0;
    
    var nextIndex = _currentIndex;
    while (nextIndex == _currentIndex) {
      nextIndex = (nextIndex + 1) % _tracks.length;
    }
    return nextIndex;
  }

  int _getPreviousShuffledIndex() {
    if (_tracks.length <= 1) return 0;
    
    var prevIndex = _currentIndex;
    while (prevIndex == _currentIndex) {
      prevIndex = (prevIndex - 1 + _tracks.length) % _tracks.length;
    }
    return prevIndex;
  }

  void _shuffleTracks() {
    _tracks.shuffle();
    // Update current index to point to same track
    if (_currentIndex >= 0 && _originalOrder.isNotEmpty) {
      final originalCurrent = _originalOrder[_currentIndex];
      _currentIndex = _tracks.indexWhere((track) => 
        _tracks.indexOf(track) == originalCurrent
      );
      if (_currentIndex == -1) _currentIndex = 0;
    }
  }

  void _restoreOriginalOrder() {
    // Simple restoration - just reset to sequential order
    // In a real implementation, you'd track the original positions
    if (_currentIndex >= 0 && _currentIndex < _tracks.length) {
      final currentTrack = _tracks[_currentIndex];
      _tracks.sort((a, b) => a.title.compareTo(b.title));
      _currentIndex = _tracks.indexOf(currentTrack);
      if (_currentIndex == -1) _currentIndex = 0;
    }
    _originalOrder.clear();
  }
}
