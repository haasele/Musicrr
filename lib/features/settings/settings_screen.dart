import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/storage/settings_repository.dart';
import '../../core/providers/provider_repository.dart';
import '../remote/remote_control_settings_screen.dart';
import '../privacy/privacy_policy_screen.dart';
import '../../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeModeTile(context, ref),
          _buildAccentColorTile(context, ref),
          
          const Divider(),
          
          // Audio Section
          _buildSectionHeader(context, 'Audio'),
          _buildOfflineModeTile(context, ref),
          
          const Divider(),
          
          // Remote Control Section
          _buildSectionHeader(context, 'Remote Control'),
          ListTile(
            title: const Text('Remote Control'),
            subtitle: const Text('Control Musicrr from your browser'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RemoteControlSettingsScreen(),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Privacy Section
          _buildSectionHeader(context, 'Privacy'),
          ListTile(
            title: const Text('Privacy Policy'),
            subtitle: const Text('View privacy policy and manage your data'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // About Section
          _buildSectionHeader(context, 'About'),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
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

  Widget _buildThemeModeTile(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(settingsRepositoryProvider).getThemeMode(),
      builder: (context, snapshot) {
        final currentMode = snapshot.data ?? 'system';
        
        return ListTile(
          title: const Text('Theme'),
          subtitle: Text(_getThemeModeLabel(currentMode)),
          trailing: PopupMenuButton<String>(
            initialValue: currentMode,
            onSelected: (value) async {
              await ref.read(settingsRepositoryProvider).setThemeMode(value);
              // Invalidate the provider to trigger rebuild
              ref.invalidate(themeModeProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Theme changed to ${_getThemeModeLabel(value)}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'light',
                child: Text('Light'),
              ),
              const PopupMenuItem(
                value: 'dark',
                child: Text('Dark'),
              ),
              const PopupMenuItem(
                value: 'system',
                child: Text('System'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccentColorTile(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int?>(
      future: ref.read(settingsRepositoryProvider).getAccentColor(),
      builder: (context, snapshot) {
        final accentColorValue = snapshot.data;
        final accentColor = accentColorValue != null ? Color(accentColorValue) : null;
        
        return ListTile(
          title: const Text('Accent Color'),
          subtitle: const Text('Customize app accent color'),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor ?? Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: () => _showColorPickerDialog(context, ref, accentColor),
        );
      },
    );
  }
  
  Future<void> _showColorPickerDialog(BuildContext context, WidgetRef ref, Color? currentColor) async {
    Color pickerColor = currentColor ?? Theme.of(context).colorScheme.primary;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Accent Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            availableColors: [
              Colors.blue,
              Colors.red,
              Colors.green,
              Colors.orange,
              Colors.purple,
              Colors.pink,
              Colors.teal,
              Colors.cyan,
              Colors.indigo,
              Colors.amber,
              Colors.brown,
              Colors.grey,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Reset to default
              await ref.read(settingsRepositoryProvider).setAccentColor(Colors.blue.value);
              // Invalidate the provider to trigger rebuild
              ref.invalidate(accentColorProvider);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Accent color reset to default')),
              );
            },
            child: const Text('Reset'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(settingsRepositoryProvider).setAccentColor(pickerColor.value);
              // Invalidate the provider to trigger rebuild
              ref.invalidate(accentColorProvider);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Accent color updated')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineModeTile(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(settingsRepositoryProvider).getOfflineMode(),
      builder: (context, snapshot) {
        final offlineMode = snapshot.data ?? false;
        
        return SwitchListTile(
          title: const Text('Offline Mode'),
          subtitle: const Text('Disable network providers'),
          value: offlineMode,
          onChanged: (value) async {
            await ref.read(settingsRepositoryProvider).setOfflineMode(value);
            ref.read(providerRepositoryProvider).setOfflineMode(value);
          },
        );
      },
    );
  }

  String _getThemeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System';
      default:
        return 'System';
    }
  }
}
