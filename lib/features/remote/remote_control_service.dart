import 'package:flutter/services.dart';

/// Service for managing the remote control web server
class RemoteControlService {
  static const MethodChannel _channel = MethodChannel('com.haasele.musicrr/remote_control');

  /// Start the remote control server
  static Future<bool> startServer({int port = 8080}) async {
    try {
      final result = await _channel.invokeMethod<bool>('startServer', {'port': port});
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to start server: ${e.message}');
    }
  }

  /// Stop the remote control server
  static Future<bool> stopServer() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopServer');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to stop server: ${e.message}');
    }
  }

  /// Check if the server is running
  static Future<bool> isServerRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServerRunning');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Get the server URL
  static Future<String> getServerUrl() async {
    try {
      final result = await _channel.invokeMethod<String>('getServerUrl');
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to get server URL: ${e.message}');
    }
  }

  /// Get the current pairing token
  static Future<String> getPairingToken() async {
    try {
      final result = await _channel.invokeMethod<String>('getPairingToken');
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to get pairing token: ${e.message}');
    }
  }

  /// Regenerate the pairing token
  static Future<String> regeneratePairingToken() async {
    try {
      final result = await _channel.invokeMethod<String>('regeneratePairingToken');
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to regenerate pairing token: ${e.message}');
    }
  }

  /// Revoke all access tokens (forces re-pairing)
  static Future<bool> revokeAllTokens() async {
    try {
      final result = await _channel.invokeMethod<bool>('revokeAllTokens');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to revoke tokens: ${e.message}');
    }
  }
}
