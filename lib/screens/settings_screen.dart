import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/sync_service.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _syncEnabled = true;
  bool _autoSync = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account Section
              _buildSectionHeader('Account'),
              Card(
                child: Column(
                  children: [
                    if (authProvider.isGuestMode)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Guest Mode'),
                        subtitle: const Text('Sign in to sync your data'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const AuthScreen(),
                              ),
                            );
                          },
                          child: const Text('Sign In'),
                        ),
                      )
                    else ...[
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(authProvider.user?.email ?? 'Signed In'),
                        subtitle: const Text('Account active'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Sign Out'),
                        onTap: () => _showSignOutDialog(context),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Security Section
              _buildSectionHeader('Security'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Encryption Passphrase'),
                      subtitle: Text(
                        authProvider.isPassphraseSet
                            ? 'Passphrase is set'
                            : 'No passphrase set',
                      ),
                      trailing: TextButton(
                        onPressed: () => _showPassphraseDialog(context),
                        child: Text(
                          authProvider.isPassphraseSet ? 'Change' : 'Set',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sync Section
              _buildSectionHeader('Sync & Backup'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.sync),
                      title: const Text('Cloud Sync'),
                      subtitle: Text(
                        authProvider.isGuestMode
                            ? 'Sign in to enable sync'
                            : 'Sync data with Firebase',
                      ),
                      value: _syncEnabled && !authProvider.isGuestMode,
                      onChanged: authProvider.isGuestMode
                          ? null
                          : (value) {
                              setState(() {
                                _syncEnabled = value;
                              });
                            },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.sync_alt),
                      title: const Text('Auto Sync'),
                      subtitle: const Text('Automatically sync when online'),
                      value:
                          _autoSync &&
                          _syncEnabled &&
                          !authProvider.isGuestMode,
                      onChanged: (_syncEnabled && !authProvider.isGuestMode)
                          ? (value) {
                              setState(() {
                                _autoSync = value;
                              });
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sync_problem),
                      title: const Text('Manual Sync'),
                      subtitle: const Text('Sync data now'),
                      trailing: Consumer<SyncService>(
                        builder: (context, syncService, child) {
                          return syncService.isSyncing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chevron_right);
                        },
                      ),
                      onTap: authProvider.isGuestMode
                          ? null
                          : () async {
                              final syncService = context.read<SyncService>();
                              await syncService.syncAll();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sync completed'),
                                  ),
                                );
                              }
                            },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.drive_folder_upload),
                      title: const Text('Export to Google Drive'),
                      subtitle: const Text('Backup notes to Google Drive'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showExportDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Data Section
              _buildSectionHeader('Data'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Storage Usage'),
                      subtitle: const Text('View local storage usage'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showStorageDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Clear All Data',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      subtitle: const Text('Delete all local data'),
                      onTap: () => _showClearDataDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader('About'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About FlowDesk'),
                      subtitle: const Text('Version 1.0.0'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAboutDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showHelpDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showPassphraseDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isChanging = authProvider.isPassphraseSet;

    showDialog(
      context: context,
      builder: (context) => PassphraseDialog(isChanging: isChanging),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export to Google Drive'),
        content: const Text(
          'This feature will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: const Text(
          'Storage usage details will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your local data including tasks, notes, and calendar events. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement clear data functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data clearing will be implemented soon'),
                ),
              );
            },
            child: Text(
              'Clear Data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FlowDesk',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.dashboard_rounded, size: 48),
      children: [
        const Text('Create, Write, Plan. No Wi-Fi Needed.'),
        const SizedBox(height: 16),
        const Text('An offline-first productivity suite built with Flutter.'),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Getting Started:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Create tasks with due dates and color tags'),
              Text('• Write encrypted notes with markdown support'),
              Text('• Schedule events on the calendar'),
              SizedBox(height: 16),
              Text(
                'Sync & Backup:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Sign in to sync data across devices'),
              Text('• Set an encryption passphrase for security'),
              Text('• Export notes to Google Drive'),
              SizedBox(height: 16),
              Text(
                'Offline Mode:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• All features work without internet'),
              Text('• Data syncs when connection is restored'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class PassphraseDialog extends StatefulWidget {
  final bool isChanging;

  const PassphraseDialog({super.key, required this.isChanging});

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassphraseController = TextEditingController();
  final _newPassphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPassphraseController.dispose();
    _newPassphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isChanging ? 'Change Passphrase' : 'Set Passphrase'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isChanging) ...[
                TextFormField(
                  controller: _currentPassphraseController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Passphrase',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrent = !_obscureCurrent;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter current passphrase';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _newPassphraseController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: widget.isChanging
                      ? 'New Passphrase'
                      : 'Passphrase',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a passphrase';
                  }
                  if (value.length < 8) {
                    return 'Passphrase must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassphraseController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Passphrase',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your passphrase';
                  }
                  if (value != _newPassphraseController.text) {
                    return 'Passphrases do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        bool success;

                        if (widget.isChanging) {
                          // Verify current passphrase first
                          final currentValid = await authProvider
                              .verifyEncryptionPassphrase(
                                _currentPassphraseController.text,
                              );

                          if (!currentValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Current passphrase is incorrect',
                                ),
                              ),
                            );
                            return;
                          }
                        }

                        success = await authProvider.setEncryptionPassphrase(
                          _newPassphraseController.text,
                        );

                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.isChanging
                                    ? 'Passphrase changed successfully'
                                    : 'Passphrase set successfully',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isChanging ? 'Change' : 'Set'),
            );
          },
        ),
      ],
    );
  }
}
