import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'remote_control_service.dart';

class RemoteControlSettingsScreen extends ConsumerStatefulWidget {
  const RemoteControlSettingsScreen({super.key});

  @override
  ConsumerState<RemoteControlSettingsScreen> createState() => _RemoteControlSettingsScreenState();
}

class _RemoteControlSettingsScreenState extends ConsumerState<RemoteControlSettingsScreen> {
  bool _isServerRunning = false;
  bool _isLoading = false;
  String _serverUrl = '';
  String _pairingToken = '';
  bool _showPairingToken = false;

  @override
  void initState() {
    super.initState();
    _loadServerState();
  }

  Future<void> _loadServerState() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isRunning = await RemoteControlService.isServerRunning();
      String url = '';
      String token = '';

      if (isRunning) {
        url = await RemoteControlService.getServerUrl();
        token = await RemoteControlService.getPairingToken();
      }

      setState(() {
        _isServerRunning = isRunning;
        _serverUrl = url;
        _pairingToken = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading server state: $e')),
        );
      }
    }
  }

  Future<void> _toggleServer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isServerRunning) {
        success = await RemoteControlService.stopServer();
      } else {
        success = await RemoteControlService.startServer();
        if (success) {
          final url = await RemoteControlService.getServerUrl();
          final token = await RemoteControlService.getPairingToken();
          setState(() {
            _serverUrl = url;
            _pairingToken = token;
          });
        }
      }

      if (success) {
        await _loadServerState();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isServerRunning
                  ? 'Failed to stop server'
                  : 'Failed to start server'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateToken() async {
    try {
      final token = await RemoteControlService.regeneratePairingToken();
      setState(() {
        _pairingToken = token;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pairing token regenerated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error regenerating token: $e')),
        );
      }
    }
  }

  Future<void> _revokeAllTokens() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke All Tokens'),
        content: const Text(
          'This will disconnect all remote control clients. They will need to pair again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RemoteControlService.revokeAllTokens();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All tokens revoked')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error revoking tokens: $e')),
          );
        }
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Control'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Server Status
                _buildSectionHeader(context, 'Server Status'),
                SwitchListTile(
                  title: const Text('Enable Remote Control'),
                  subtitle: Text(_isServerRunning
                      ? 'Server is running'
                      : 'Server is stopped'),
                  value: _isServerRunning,
                  onChanged: _isLoading ? null : (_) => _toggleServer(),
                ),

                if (_isServerRunning) ...[
                  const Divider(),

                  // Server Information
                  _buildSectionHeader(context, 'Connection Information'),
                  ListTile(
                    title: const Text('Server URL'),
                    subtitle: Text(
                      _serverUrl.isNotEmpty ? _serverUrl : 'Not available',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _serverUrl.isNotEmpty
                          ? () => _copyToClipboard(_serverUrl, 'Server URL')
                          : null,
                    ),
                  ),

                  // Pairing Token
                  ListTile(
                    title: const Text('Pairing Token'),
                    subtitle: Text(
                      _showPairingToken
                          ? _pairingToken
                          : '••••••••',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _showPairingToken
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPairingToken = !_showPairingToken;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _pairingToken.isNotEmpty
                              ? () => _copyToClipboard(_pairingToken, 'Pairing token')
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Enter this token in the web interface to connect.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),

                  const Divider(),

                  // Actions
                  _buildSectionHeader(context, 'Actions'),
                  ListTile(
                    title: const Text('Regenerate Pairing Token'),
                    subtitle: const Text('Generate a new pairing token'),
                    trailing: const Icon(Icons.refresh),
                    onTap: _regenerateToken,
                  ),
                  ListTile(
                    title: const Text('Revoke All Tokens'),
                    subtitle: const Text('Disconnect all clients'),
                    trailing: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onTap: _revokeAllTokens,
                  ),
                ],

                const Divider(),

                // Information
                _buildSectionHeader(context, 'Information'),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remote Control allows you to control Musicrr from any device on your local network using a web browser.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• The server is only accessible on your local network',
                      ),
                      Text(
                        '• You need to pair using the pairing token',
                      ),
                      Text(
                        '• All communication is local (no internet required)',
                      ),
                    ],
                  ),
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
}
