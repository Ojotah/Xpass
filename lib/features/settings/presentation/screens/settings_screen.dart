import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/password_strength_validator.dart';
import '../../../vault/presentation/providers/vault_providers.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_vault.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppSettings? _draft;
  bool _saving = false;

  Future<void> _apply() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);
    await ref.read(settingsControllerProvider.notifier).saveSettings(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Applied.')));
  }

  void _discard(AppSettings settings) {
    setState(() => _draft = settings);
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
          _draft ??= settings;
          final draft = _draft!;
          final activeVault = draft.activeVault;

          return Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
                              DropdownButtonFormField<ThemeMode>(
                                initialValue: draft.themeMode,
                                decoration: const InputDecoration(labelText: 'Theme'),
                                items: const [
                                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                                ],
                                onChanged: (value) =>
                                    setState(() => _draft = draft.copyWith(themeMode: value)),
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
                              SwitchListTile(
                                value: draft.biometricEnabled,
                                title: const Text('Enable biometric unlock'),
                                onChanged: (value) =>
                                    setState(() => _draft = draft.copyWith(biometricEnabled: value)),
                              ),
                              DropdownButtonFormField<int>(
                                initialValue: draft.autoLockTimeout,
                                decoration:
                                    const InputDecoration(labelText: 'Auto-lock timeout (minutes)'),
                                items: const [1, 3, 5, 10, 15]
                                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _draft = draft.copyWith(autoLockTimeout: value)),
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
                              Text('Clipboard', style: Theme.of(context).textTheme.titleLarge),
                              SwitchListTile(
                                value: draft.clipboardClearEnabled,
                                title: const Text('Auto-clear clipboard'),
                                onChanged: (value) => setState(
                                  () => _draft = draft.copyWith(clipboardClearEnabled: value),
                                ),
                              ),
                              DropdownButtonFormField<int>(
                                initialValue: draft.clipboardClearDuration,
                                decoration:
                                    const InputDecoration(labelText: 'Clipboard clear duration (sec)'),
                                items: const [10, 15, 30, 60]
                                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                                    .toList(),
                                onChanged: draft.clipboardClearEnabled
                                    ? (value) => setState(
                                          () => _draft =
                                              draft.copyWith(clipboardClearDuration: value),
                                        )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('Password Hint'),
                          subtitle: Text(
                            activeVault.passwordHint.isEmpty
                                ? 'No hint set'
                                : activeVault.passwordHint,
                          ),
                        ),
                      ),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Change master password'),
                              trailing: FilledButton(
                                onPressed: _showChangeMasterPasswordDialog,
                                child: const Text('Change'),
                              ),
                            ),
                            ListTile(
                              title: const Text('Export active vault'),
                              trailing: FilledButton(
                                onPressed: () => _exportVault(activeVault),
                                child: const Text('Export'),
                              ),
                            ),
                            ListTile(
                              title: const Text('Import vault file'),
                              trailing: FilledButton(
                                onPressed: () => _importVault(activeVault),
                                child: const Text('Import'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => _discard(settings),
                        child: const Text('Discard changes'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _saving ? null : _apply,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportVault(AppVault vault) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export encrypted vault',
      fileName: '${vault.name.replaceAll(' ', '_')}.dat',
    );
    if (path == null) return;

    try {
      await ref.read(exportVaultUseCaseProvider).call(vaultId: vault.id, targetPath: path);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vault exported.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Export failed.')));
    }
  }

  Future<void> _importVault(AppVault activeVault) async {
    final pick = await FilePicker.platform.pickFiles(type: FileType.any);
    final sourcePath = pick?.files.single.path;
    if (sourcePath == null) return;

    if (!mounted) return;
    final overwrite = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import options'),
        content: const Text('Overwrite active vault? Choose cancel to add as new vault.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
          OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Add new')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Overwrite')),
        ],
      ),
    );

    if (overwrite == null) return;
    final vaultId = overwrite ? activeVault.id : DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await ref.read(importVaultUseCaseProvider).call(vaultId: vaultId, sourcePath: sourcePath);
      if (!overwrite) {
        await ref.read(settingsControllerProvider.notifier).upsertVault(
              AppVault(id: vaultId, name: 'Imported Vault', passwordHint: ''),
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Import complete.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Import failed.')));
    }
  }

  Future<void> _showChangeMasterPasswordDialog() async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();
    final hintController = TextEditingController(
      text: ref.read(settingsControllerProvider).valueOrNull?.activeVault.passwordHint ?? '',
    );
    bool hintOnly = false;
    final formKey = GlobalKey<FormState>();

    final changed = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool busy = false;
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Change Master Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: hintOnly,
                    onChanged: (value) => setStateDialog(() => hintOnly = value),
                    title: const Text('Change password hint only'),
                  ),
                  if (!hintOnly) ...[
                    TextFormField(
                      controller: currentController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: nextController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      validator: (value) => PasswordStrengthValidator.validate(value ?? ''),
                    ),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password'),
                      validator: (value) =>
                          value != nextController.text ? 'Passwords do not match' : null,
                    ),
                  ],
                  TextFormField(
                    controller: hintController,
                    decoration: const InputDecoration(labelText: 'Password hint'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        setStateDialog(() => busy = true);
                        try {
                          if (!hintOnly) {
                            await ref.read(vaultControllerProvider.notifier).changeMasterPassword(
                                  currentPassword: currentController.text,
                                  newPassword: nextController.text,
                                );
                          }
                          final settings = ref.read(settingsControllerProvider).valueOrNull;
                          if (settings != null) {
                            final updatedVault =
                                settings.activeVault.copyWith(passwordHint: hintController.text.trim());
                            await ref.read(settingsControllerProvider.notifier).upsertVault(updatedVault);
                          }
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
                            const SnackBar(content: Text('Unable to update password/hint.')),
                          );
                          setStateDialog(() => busy = false);
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    currentController.dispose();
    nextController.dispose();
    confirmController.dispose();
    hintController.dispose();

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password settings updated.')),
      );
    }
  }
}
