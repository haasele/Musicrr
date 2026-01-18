import 'package:flutter/services.dart';

class AudioPlatformChannels {
  static const MethodChannel _methodChannel = MethodChannel('com.haasele.musicrr/audio');
  static const EventChannel _eventChannel = EventChannel('com.haasele.musicrr/audio_events');

  // MethodChannel methods
  static Future<void> play(String uri) async {
    try {
      await _methodChannel.invokeMethod('play', {'uri': uri});
    } on PlatformException catch (e) {
      throw Exception('Failed to play: ${e.message}');
    }
  }

  static Future<void> playQueue(List<String> uris, {int startIndex = 0}) async {
    try {
      await _methodChannel.invokeMethod('playQueue', {
        'uris': uris,
        'startIndex': startIndex,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to play queue: ${e.message}');
    }
  }

  static Future<void> pause() async {
    try {
      await _methodChannel.invokeMethod('pause');
    } on PlatformException catch (e) {
      throw Exception('Failed to pause: ${e.message}');
    }
  }

  static Future<void> resume() async {
    try {
      await _methodChannel.invokeMethod('resume');
    } on PlatformException catch (e) {
      throw Exception('Failed to resume: ${e.message}');
    }
  }

  static Future<void> seek(int positionMs) async {
    try {
      await _methodChannel.invokeMethod('seek', {'positionMs': positionMs});
    } on PlatformException catch (e) {
      throw Exception('Failed to seek: ${e.message}');
    }
  }

  static Future<void> setVolume(double volume) async {
    try {
      await _methodChannel.invokeMethod('setVolume', {'volume': volume});
    } on PlatformException catch (e) {
      throw Exception('Failed to set volume: ${e.message}');
    }
  }

  static Future<void> setEQ(List<Map<String, dynamic>> bands) async {
    try {
      await _methodChannel.invokeMethod('setEQ', {'bands': bands});
    } on PlatformException catch (e) {
      throw Exception('Failed to set EQ: ${e.message}');
    }
  }

  static Future<void> setReplayGain(double gainDb) async {
    try {
      await _methodChannel.invokeMethod('setReplayGain', {'gainDb': gainDb});
    } on PlatformException catch (e) {
      throw Exception('Failed to set ReplayGain: ${e.message}');
    }
  }

  static Future<void> enableCrossfade(bool enabled, int durationMs) async {
    try {
      await _methodChannel.invokeMethod('enableCrossfade', {
        'enabled': enabled,
        'durationMs': durationMs,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to enable crossfade: ${e.message}');
    }
  }

  static Future<void> setSampleRate(int sampleRate) async {
    try {
      await _methodChannel.invokeMethod('setSampleRate', {'sampleRate': sampleRate});
    } on PlatformException catch (e) {
      throw Exception('Failed to set sample rate: ${e.message}');
    }
  }

  static Future<void> loadVisualizerPreset(String presetPath) async {
    try {
      await _methodChannel.invokeMethod('loadVisualizerPreset', {'presetPath': presetPath});
    } on PlatformException catch (e) {
      throw Exception('Failed to load visualizer preset: ${e.message}');
    }
  }

  static Future<void> setVisualizerEnabled(bool enabled) async {
    try {
      await _methodChannel.invokeMethod('setVisualizerEnabled', {'enabled': enabled});
    } on PlatformException catch (e) {
      throw Exception('Failed to set visualizer enabled: ${e.message}');
    }
  }

  // EventChannel stream
  static Stream<Map<String, dynamic>> get playbackEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
  }
}
