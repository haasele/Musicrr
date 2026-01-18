import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/privacy/data_export_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  bool _isExporting = false;
  bool _isDeleting = false;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = await ref.read(dataExportServiceProvider);
      final exportPath = await exportService.exportAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: ${p.basename(exportPath)}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                Share.shareXFiles([XFile(exportPath)], text: 'Musicrr Data Export');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your data including:\n\n'
          '• Playback history\n'
          '• Lyrics\n'
          '• Presets\n'
          '• Saved queues\n'
          '• Settings\n\n'
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final exportService = await ref.read(dataExportServiceProvider);
      await exportService.deleteAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting data: $e')),
        );
      }
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Policy
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    context,
                    'Data Collection',
                    'Musicrr collects and stores the following data locally on your device:\n\n'
                    '• Playback analytics (play count, duration, skip rate) - Used for recommendations\n'
                    '• Lyrics - User-added or cached lyrics\n'
                    '• Now Playing presets - Your custom layouts\n'
                    '• Queue snapshots - Saved playback queues\n'
                    '• Download metadata - Download progress and status\n'
                    '• Cache metadata - Cached file information\n'
                    '• Settings - App preferences and configuration\n\n'
                    'All data is stored locally and never transmitted to external servers.',
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    context,
                    'No Tracking',
                    'Musicrr does not:\n\n'
                    '• Track your location\n'
                    '• Send data to analytics services\n'
                    '• Use advertising trackers\n'
                    '• Collect personal information\n'
                    '• Share data with third parties\n\n'
                    'All analytics are local-only and used solely for music recommendations.',
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    context,
                    'Network Providers',
                    'When using network providers (WebDAV, SMB, Subsonic, Jellyfin):\n\n'
                    '• Credentials are stored locally and encrypted\n'
                    '• All communication is direct to your servers\n'
                    '• No data passes through Musicrr servers\n'
                    '• You control all network access',
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    context,
                    'Remote Control',
                    'The remote control web server:\n\n'
                    '• Only accessible on your local network\n'
                    '• Uses token-based authentication\n'
                    '• No external connections\n'
                    '• All communication is local',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Export All Data'),
                    subtitle: const Text('Download a copy of all your data (JSON format)'),
                    trailing: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isExporting ? null : _exportData,
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Delete All Data',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: const Text('Permanently delete all stored data'),
                    trailing: _isDeleting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          )
                        : Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.error,
                          ),
                    onTap: _isDeleting ? null : _deleteAllData,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data Types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Types',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeItem(
                    context,
                    'Playback Analytics',
                    'Tracks when and how long you play songs, used for recommendations',
                  ),
                  _buildDataTypeItem(
                    context,
                    'Lyrics',
                    'User-added or cached lyrics for songs',
                  ),
                  _buildDataTypeItem(
                    context,
                    'Presets',
                    'Custom Now Playing screen layouts',
                  ),
                  _buildDataTypeItem(
                    context,
                    'Queues',
                    'Saved playback queue snapshots',
                  ),
                  _buildDataTypeItem(
                    context,
                    'Downloads',
                    'Download progress and metadata',
                  ),
                  _buildDataTypeItem(
                    context,
                    'Cache',
                    'Metadata about cached audio files',
                  ),
                  _buildDataTypeItem(
                    context,
                    'Settings',
                    'App preferences and configuration',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDataTypeItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
