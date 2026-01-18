import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderSettings {
  final String providerId;
  final bool autoSyncEnabled;
  final int syncIntervalMinutes; // 0 = manual only
  final bool cacheEnabled;
  final int? cacheSizeLimitMB; // null = use global limit
  final bool transcodingEnabled;
  final String? transcodingProfileId;
  final DateTime? lastSyncTime;

  const ProviderSettings({
    required this.providerId,
    this.autoSyncEnabled = false,
    this.syncIntervalMinutes = 0,
    this.cacheEnabled = true,
    this.cacheSizeLimitMB,
    this.transcodingEnabled = false,
    this.transcodingProfileId,
    this.lastSyncTime,
  });

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'autoSyncEnabled': autoSyncEnabled,
        'syncIntervalMinutes': syncIntervalMinutes,
        'cacheEnabled': cacheEnabled,
        'cacheSizeLimitMB': cacheSizeLimitMB,
        'transcodingEnabled': transcodingEnabled,
        'transcodingProfileId': transcodingProfileId,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      };

  factory ProviderSettings.fromJson(Map<String, dynamic> json) => ProviderSettings(
        providerId: json['providerId'] as String,
        autoSyncEnabled: json['autoSyncEnabled'] as bool? ?? false,
        syncIntervalMinutes: json['syncIntervalMinutes'] as int? ?? 0,
        cacheEnabled: json['cacheEnabled'] as bool? ?? true,
        cacheSizeLimitMB: json['cacheSizeLimitMB'] as int?,
        transcodingEnabled: json['transcodingEnabled'] as bool? ?? false,
        transcodingProfileId: json['transcodingProfileId'] as String?,
        lastSyncTime: json['lastSyncTime'] != null
            ? DateTime.parse(json['lastSyncTime'] as String)
            : null,
      );
}

class ProviderSettingsRepository {
  static const String _prefix = 'provider_settings_';

  Future<ProviderSettings> getSettings(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$providerId';
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      return ProviderSettings(providerId: providerId);
    }

    try {
      // Simplified storage - in production, use JSON encoding
      return ProviderSettings(
        providerId: providerId,
        autoSyncEnabled: prefs.getBool('${key}_autoSync') ?? false,
        syncIntervalMinutes: prefs.getInt('${key}_syncInterval') ?? 0,
        cacheEnabled: prefs.getBool('${key}_cacheEnabled') ?? true,
        cacheSizeLimitMB: prefs.getInt('${key}_cacheSizeMB'),
        transcodingEnabled: prefs.getBool('${key}_transcodingEnabled') ?? false,
        transcodingProfileId: prefs.getString('${key}_transcodingProfile'),
        lastSyncTime: prefs.getString('${key}_lastSyncTime') != null
            ? DateTime.parse(prefs.getString('${key}_lastSyncTime')!)
            : null,
      );
    } catch (e) {
      return ProviderSettings(providerId: providerId);
    }
  }

  Future<void> saveSettings(ProviderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${settings.providerId}';

    await prefs.setBool('${key}_autoSync', settings.autoSyncEnabled);
    await prefs.setInt('${key}_syncInterval', settings.syncIntervalMinutes);
    await prefs.setBool('${key}_cacheEnabled', settings.cacheEnabled);
    if (settings.cacheSizeLimitMB != null) {
      await prefs.setInt('${key}_cacheSizeMB', settings.cacheSizeLimitMB!);
    } else {
      await prefs.remove('${key}_cacheSizeMB');
    }
    await prefs.setBool('${key}_transcodingEnabled', settings.transcodingEnabled);
    if (settings.transcodingProfileId != null) {
      await prefs.setString('${key}_transcodingProfile', settings.transcodingProfileId!);
    } else {
      await prefs.remove('${key}_transcodingProfile');
    }
    if (settings.lastSyncTime != null) {
      await prefs.setString('${key}_lastSyncTime', settings.lastSyncTime!.toIso8601String());
    } else {
      await prefs.remove('${key}_lastSyncTime');
    }
  }

  Future<void> setLastSyncTime(String providerId, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$providerId';
    await prefs.setString('${key}_lastSyncTime', time.toIso8601String());
  }
}

final providerSettingsRepositoryProvider = Provider<ProviderSettingsRepository>((ref) {
  return ProviderSettingsRepository();
});
