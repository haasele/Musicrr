import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class StoragePermissionService {
  /// Check if storage permissions are granted
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      // Try audio permission first (Android 13+)
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted) {
        return true;
      }
      
      // Try storage permission (Android < 13)
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      
      return false;
    }
    // On other platforms, assume permission is granted
    return true;
  }

  /// Request storage permissions
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Request audio permission first (Android 13+)
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) {
        return true;
      }
      
      // If audio permission is permanently denied, try storage permission
      if (audioStatus.isPermanentlyDenied) {
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      }
      
      // Try storage permission as fallback (Android < 13)
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    // On other platforms, assume permission is granted
    return true;
  }

  /// Check and request storage permissions if needed
  static Future<bool> ensureStoragePermission() async {
    if (await hasStoragePermission()) {
      return true;
    }
    return await requestStoragePermission();
  }
}
