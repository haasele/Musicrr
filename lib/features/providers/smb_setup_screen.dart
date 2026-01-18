import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/provider_repository.dart';
import '../../core/providers/smb_provider.dart';

class SMBSetupScreen extends ConsumerStatefulWidget {
  const SMBSetupScreen({super.key});

  @override
  ConsumerState<SMBSetupScreen> createState() => _SMBSetupScreenState();
}

class _SMBSetupScreenState extends ConsumerState<SMBSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  final _shareController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _workgroupController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _shareController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _workgroupController.dispose();
    super.dispose();
  }

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = SMBProvider(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        server: _serverController.text.trim(),
        share: _shareController.text.trim(),
        username: _usernameController.text.trim().isEmpty 
            ? null 
            : _usernameController.text.trim(),
        password: _passwordController.text.trim().isEmpty 
            ? null 
            : _passwordController.text.trim(),
        workgroup: _workgroupController.text.trim().isEmpty 
            ? null 
            : _workgroupController.text.trim(),
      );

      await provider.initialize();

      final repository = ref.read(providerRepositoryProvider);
      await repository.addProvider(provider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMB provider added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding provider: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add SMB Provider'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Provider Name',
                hintText: 'My SMB Share',
                helperText: 'A friendly name for this provider',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Server Address',
                hintText: '192.168.1.100 or server.local',
                helperText: 'IP address or hostname of the SMB server',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a server address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shareController,
              decoration: const InputDecoration(
                labelText: 'Share Name',
                hintText: 'Music',
                helperText: 'Name of the SMB share',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a share name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _workgroupController,
              decoration: const InputDecoration(
                labelText: 'Workgroup (optional)',
                hintText: 'WORKGROUP',
                helperText: 'Leave empty for default',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (optional)',
                hintText: 'Leave empty for guest access',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password (optional)',
                hintText: 'Leave empty for guest access',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _saveProvider,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Provider'),
            ),
          ],
        ),
      ),
    );
  }
}
