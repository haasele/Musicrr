import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/webdav_setup_screen.dart';
import '../providers/smb_setup_screen.dart';
import '../providers/subsonic_setup_screen.dart';
import '../providers/jellyfin_setup_screen.dart';
import 'provider_list_view.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Provider',
            onPressed: _showAddProviderDialog,
          ),
        ],
      ),
      body: const ProviderListView(),
    );
  }
  
  void _showAddProviderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('WebDAV'),
              subtitle: const Text('Access music from WebDAV server'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebDAVSetupScreen(),
                  ),
                ).then((added) {
                  if (added == true && mounted) {
                    setState(() {});
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('SMB/CIFS'),
              subtitle: const Text('Access music from network share'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SMBSetupScreen(),
                  ),
                ).then((added) {
                  if (added == true && mounted) {
                    setState(() {});
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Subsonic'),
              subtitle: const Text('Connect to Subsonic server'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubsonicSetupScreen(),
                  ),
                ).then((added) {
                  if (added == true && mounted) {
                    setState(() {});
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music),
              title: const Text('Jellyfin'),
              subtitle: const Text('Connect to Jellyfin server'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JellyfinSetupScreen(),
                  ),
                ).then((added) {
                  if (added == true && mounted) {
                    setState(() {});
                  }
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
