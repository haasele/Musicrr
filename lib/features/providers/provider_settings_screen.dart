import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/providers/provider_repository.dart';
import '../../core/providers/local_provider.dart';
import '../../core/storage/provider_settings_repository.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/transcoding/transcoding_service.dart';
import 'package:intl/intl.dart';

class ProviderSettingsScreen extends ConsumerStatefulWidget {
  final String providerId;

  const ProviderSettingsScreen({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends ConsumerState<ProviderSettingsScreen> {
  ProviderSettings? _settings;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(providerSettingsRepositoryProvider);
      final settings = await repository.getSettings(widget.providerId);
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings(ProviderSettings settings) async {
    try {
      final repository = ref.read(providerSettingsRepositoryProvider);
      await repository.saveSettings(settings);
      setState(() {
        _settings = settings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _syncProvider() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final providerRepo = ref.read(providerRepositoryProvider);
      await providerRepo.syncProvider(widget.providerId, incremental: true);

      // Update last sync time
      final settingsRepo = ref.read(providerSettingsRepositoryProvider);
      await settingsRepo.setLastSyncTime(widget.providerId, DateTime.now());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed')),
        );
        await _loadSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerRepo = ref.watch(providerRepositoryProvider);
    final provider = providerRepo.providers.firstWhere(
      (p) => p.id == widget.providerId,
      orElse: () => throw Exception('Provider not found'),
    );
    
    // Check if this is a LocalProvider
    final isLocalProvider = provider.runtimeType.toString() == 'LocalProvider';

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Settings not available'))
              : ListView(
                  children: [
                    // Provider Status
                    _buildSectionHeader(context, 'Provider Status'),
                    SwitchListTile(
                      title: const Text('Enable Provider'),
                      subtitle: Text(provider.isEnabled
                          ? 'Provider is active'
                          : 'Provider is disabled'),
                      value: provider.isEnabled,
                      onChanged: (value) async {
                        final repository = ref.read(providerRepositoryProvider);
                        await repository.setProviderEnabled(widget.providerId, value);
                        if (!mounted) return;
                        setState(() {});
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value 
                                  ? 'Provider enabled' 
                                  : 'Provider disabled',
                            ),
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // Local Provider specific: Music Folders
                    if (isLocalProvider) ...[
                      _buildSectionHeader(context, 'Music Folders'),
                      _buildLocalProviderFolders(context, ref),
                      const Divider(),
                    ],

                    // Sync Settings (only for network providers)
                    if (!isLocalProvider) ...[
                      _buildSectionHeader(context, 'Sync Settings'),
                    SwitchListTile(
                      title: const Text('Auto Sync'),
                      subtitle: Text(_settings!.autoSyncEnabled
                          ? 'Automatically sync this provider'
                          : 'Manual sync only'),
                      value: _settings!.autoSyncEnabled,
                      onChanged: (value) {
                        _saveSettings(_settings!.copyWith(autoSyncEnabled: value));
                      },
                    ),
                    if (_settings!.autoSyncEnabled)
                      ListTile(
                        title: const Text('Sync Interval'),
                        subtitle: Text(_getSyncIntervalText(_settings!.syncIntervalMinutes)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showSyncIntervalDialog(),
                      ),
                    ListTile(
                      title: const Text('Last Sync'),
                      subtitle: Text(
                        _settings!.lastSyncTime != null
                            ? DateFormat.yMd().add_jm().format(_settings!.lastSyncTime!)
                            : 'Never synced',
                      ),
                      trailing: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _isSyncing ? null : _syncProvider,
                              tooltip: 'Sync now',
                            ),
                    ),

                      const Divider(),

                      // Cache Settings (only for network providers)
                      _buildSectionHeader(context, 'Cache Settings'),
                      SwitchListTile(
                        title: const Text('Enable Caching'),
                        subtitle: const Text('Cache files for offline playback'),
                        value: _settings!.cacheEnabled,
                        onChanged: (value) {
                          _saveSettings(_settings!.copyWith(cacheEnabled: value));
                        },
                      ),
                      if (_settings!.cacheEnabled)
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getCacheStats(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final stats = snapshot.data!;
                              return ListTile(
                                title: const Text('Cache Usage'),
                                subtitle: Text(
                                  '${stats['usedMB']} MB / ${stats['limitMB']} MB (${stats['usagePercent']}%)',
                                ),
                                trailing: TextButton(
                                  onPressed: () => _showClearCacheDialog(),
                                  child: const Text('Clear Cache'),
                                ),
                              );
                            }
                            return const ListTile(
                              title: Text('Cache Usage'),
                              subtitle: Text('Loading...'),
                            );
                          },
                        ),

                      const Divider(),

                      // Transcoding Settings (only for network providers)
                      _buildSectionHeader(context, 'Transcoding'),
                      SwitchListTile(
                        title: const Text('Enable Transcoding'),
                        subtitle: const Text('Transcode files for better compatibility'),
                        value: _settings!.transcodingEnabled,
                        onChanged: (value) {
                          _saveSettings(_settings!.copyWith(transcodingEnabled: value));
                        },
                      ),
                      if (_settings!.transcodingEnabled)
                        FutureBuilder<List<TranscodeProfile>>(
                          future: _getTranscodeProfiles(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final profiles = snapshot.data!;
                              final currentProfile = profiles.firstWhere(
                                (p) => p.id == _settings!.transcodingProfileId,
                                orElse: () => profiles.first,
                              );
                              return ListTile(
                                title: const Text('Transcode Profile'),
                                subtitle: Text(currentProfile.name),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _showTranscodeProfileDialog(profiles),
                              );
                            }
                            return const ListTile(
                              title: Text('Transcode Profile'),
                              subtitle: Text('Loading...'),
                            );
                          },
                        ),

                      const Divider(),
                    ],

                    // Provider Info
                    _buildSectionHeader(context, 'Provider Information'),
                    ListTile(
                      title: const Text('Provider ID'),
                      subtitle: Text(provider.id),
                    ),
                    ListTile(
                      title: const Text('Provider Type'),
                      subtitle: Text(provider.runtimeType.toString()),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  String _getSyncIntervalText(int minutes) {
    if (minutes == 0) return 'Manual only';
    if (minutes < 60) return 'Every $minutes minutes';
    if (minutes < 1440) return 'Every ${minutes ~/ 60} hours';
    return 'Every ${minutes ~/ 1440} days';
  }

  Future<void> _showSyncIntervalDialog() async {
    final intervals = [0, 15, 30, 60, 120, 240, 1440]; // minutes
    final intervalLabels = [
      'Manual only',
      'Every 15 minutes',
      'Every 30 minutes',
      'Every hour',
      'Every 2 hours',
      'Every 4 hours',
      'Daily',
    ];

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.asMap().entries.map((entry) {
            final index = entry.key;
            final minutes = entry.value;
            return RadioListTile<int>(
              title: Text(intervalLabels[index]),
              value: minutes,
              groupValue: _settings!.syncIntervalMinutes,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      _saveSettings(_settings!.copyWith(syncIntervalMinutes: selected));
    }
  }

  Future<void> _showTranscodeProfileDialog(List<TranscodeProfile> profiles) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transcode Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: profiles.map((profile) {
            return RadioListTile<String>(
              title: Text(profile.name),
              subtitle: Text('${profile.bitrate} kbps'),
              value: profile.id,
              groupValue: _settings!.transcodingProfileId ?? profiles.first.id,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      _saveSettings(_settings!.copyWith(transcodingProfileId: selected));
    }
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached files for this provider. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final cacheManagerFuture = ref.read(cacheManagerProvider);
        final cacheManager = await cacheManagerFuture;
        // TODO: Implement per-provider cache clearing
        await cacheManager.clearCache();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing cache: $e')),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>> _getCacheStats() async {
    try {
      final cacheManagerFuture = ref.read(cacheManagerProvider);
      final cacheManager = await cacheManagerFuture;
      final stats = await cacheManager.getCacheStats();
      
      // Filter by provider (simplified - in production, would filter by providerId)
      return {
        'usedMB': stats['totalSizeMB'],
        'limitMB': stats['maxSizeMB'],
        'usagePercent': stats['usagePercent'],
      };
    } catch (e) {
      return {
        'usedMB': '0',
        'limitMB': '1024',
        'usagePercent': '0',
      };
    }
  }

  Future<List<TranscodeProfile>> _getTranscodeProfiles() async {
    try {
      final transcodingServiceFuture = ref.read(transcodingServiceProvider);
      final transcodingService = await transcodingServiceFuture;
      return transcodingService.getAvailableProfiles();
    } catch (e) {
      return [
        TranscodeProfile.flacToOpus,
        TranscodeProfile.flacToMp3,
      ];
    }
  }
  
  Widget _buildLocalProviderFolders(BuildContext context, WidgetRef ref) {
    final providerRepo = ref.watch(providerRepositoryProvider);
    final provider = providerRepo.providers.firstWhere(
      (p) => p.id == widget.providerId,
    );
    
    if (provider is! LocalProvider) {
      return const SizedBox.shrink();
    }
    
    return FutureBuilder<List<String>>(
      future: Future.value(provider.getMusicDirectories()),
      builder: (context, snapshot) {
        final directories = snapshot.data ?? [];
        
        return Column(
          children: [
            if (directories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No music folders selected. Add a folder to scan for music files.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ...directories.map((dir) => ListTile(
              leading: const Icon(Icons.folder),
              title: Text(dir),
              subtitle: const Text('Music folder'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Rescan folder',
                    onPressed: () => _rescanFolder(context, ref, provider, dir),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Remove folder',
                    onPressed: () async {
                      await provider.removeMusicDirectory(dir);
                      setState(() {});
                    },
                  ),
                ],
              ),
            )),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Music Folder'),
              subtitle: const Text('Select a folder to scan for music'),
              onTap: () => _showAddFolderDialog(context, ref, provider),
            ),
            if (directories.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Rescan All Folders'),
                subtitle: const Text('Refresh music library from all folders'),
                onTap: () => _rescanAllFolders(context, ref, provider),
              ),
          ],
        );
      },
    );
  }
  
  Future<void> _rescanFolder(BuildContext context, WidgetRef ref, LocalProvider provider, String dirPath) async {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanning folder...')),
    );
    
    try {
      // Clear cache to force rescan
      await provider.clearCache();
      final repository = ref.read(providerRepositoryProvider);
      final songs = await repository.getSongs();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${songs.length} songs'),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Refresh the UI
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning: $e'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }
  
  Future<void> _rescanAllFolders(BuildContext context, WidgetRef ref, LocalProvider provider) async {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanning all folders...')),
    );
    
    try {
      // Clear cache to force rescan
      await provider.clearCache();
      final repository = ref.read(providerRepositoryProvider);
      final songs = await repository.getSongs();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${songs.length} songs in all folders'),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Refresh the UI
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning: $e'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }
  
  Future<void> _showAddFolderDialog(BuildContext context, WidgetRef ref, LocalProvider provider) async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Music Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Folder Path',
                hintText: '/storage/emulated/0/Music',
                helperText: 'Enter the full path to your music folder',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                try {
                  // Use file_picker to select directory
                  final directory = await FilePicker.platform.getDirectoryPath();
                  if (directory != null) {
                    controller.text = directory;
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error selecting folder: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result != null && result.trim().isNotEmpty) {
      try {
        final directory = Directory(result.trim());
        if (await directory.exists()) {
          await provider.addMusicDirectory(result.trim());
          if (!mounted) return;
          setState(() {});
          if (!mounted) return;
          
          // Automatically trigger a scan after adding folder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder added. Scanning for music...')),
          );
          
          // Trigger a rescan by clearing cache
          try {
            await provider.clearCache();
            final repository = ref.read(providerRepositoryProvider);
            final songs = await repository.getSongs();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Found ${songs.length} songs')),
            );
          } catch (scanError) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Folder added but scan failed: $scanError')),
            );
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder does not exist: $result')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding folder: $e')),
        );
      }
    }
  }
}

// Extension to add copyWith method to ProviderSettings
extension ProviderSettingsExtension on ProviderSettings {
  ProviderSettings copyWith({
    bool? autoSyncEnabled,
    int? syncIntervalMinutes,
    bool? cacheEnabled,
    int? cacheSizeLimitMB,
    bool? transcodingEnabled,
    String? transcodingProfileId,
    DateTime? lastSyncTime,
  }) {
    return ProviderSettings(
      providerId: providerId,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
      cacheSizeLimitMB: cacheSizeLimitMB ?? this.cacheSizeLimitMB,
      transcodingEnabled: transcodingEnabled ?? this.transcodingEnabled,
      transcodingProfileId: transcodingProfileId ?? this.transcodingProfileId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}
