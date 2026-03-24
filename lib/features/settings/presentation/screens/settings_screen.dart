import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/password_strength_validator.dart';
import '../../../vault/presentation/providers/vault_providers.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;

  Future<void> _save(AppSettings settings) async {
    setState(() => _saving = true);
    await ref.read(settingsControllerProvider.notifier).update(settings);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved.')));
    }
  }

  Future<void> _showChangeMasterPasswordDialog() async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final changed = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool busy = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Change Master Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: nextController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return PasswordStrengthValidator.validate(value);
                      },
                    ),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password'),
                      validator: (value) {
                        if (value != nextController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setStateDialog(() => busy = true);
                          try {
                            await ref.read(vaultControllerProvider.notifier).changeMasterPassword(
                                  currentPassword: currentController.text,
                                  newPassword: nextController.text,
                                );
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          } on WrongPasswordException {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Current password is incorrect.')),
                            );
                            setStateDialog(() => busy = false);
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unable to change password.')),
                            );
                            setStateDialog(() => busy = false);
                          }
                        },
                  child: const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    nextController.dispose();
    confirmController.dispose();

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master password changed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load settings.')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('General'),
                  subtitle: Text('Vault name: ${settings.vaultName}'),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vault Name', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: settings.vaultName,
                        onChanged: (value) => _save(settings.copyWith(vaultName: value.trim())),
                      ),
                      const SizedBox(height: 12),
                      Text('Password Hint', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: settings.passwordHint,
                        onChanged: (value) => _save(settings.copyWith(passwordHint: value.trim())),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security', style: Theme.of(context).textTheme.titleLarge),
                      DropdownButtonFormField<int>(
                        value: settings.autoLockTimeout,
                        decoration: const InputDecoration(labelText: 'Auto-lock timeout (minutes)'),
                        items: const [1, 3, 5, 10, 15]
                            .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _save(settings.copyWith(autoLockTimeout: value));
                        },
                      ),
                      SwitchListTile(
                        value: settings.clipboardClearEnabled,
                        title: const Text('Auto-clear clipboard'),
                        onChanged: (value) {
                          _save(settings.copyWith(clipboardClearEnabled: value));
                        },
                      ),
                      DropdownButtonFormField<int>(
                        value: settings.clipboardClearDuration,
                        decoration: const InputDecoration(labelText: 'Clipboard clear duration (sec)'),
                        items: const [10, 15, 30, 60]
                            .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                            .toList(),
                        onChanged: settings.clipboardClearEnabled
                            ? (value) {
                                if (value == null) return;
                                _save(settings.copyWith(clipboardClearDuration: value));
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Account'),
                  subtitle: const Text('Change master password'),
                  trailing: FilledButton(
                    onPressed: _showChangeMasterPasswordDialog,
                    child: const Text('Change'),
                  ),
                ),
              ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}
