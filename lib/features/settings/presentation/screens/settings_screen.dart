import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/password_strength_validator.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/top_right_notification.dart';
import '../../../vault/presentation/providers/vault_providers.dart';
import '../../../vault/domain/entities/vault_metadata.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_vault.dart';
import '../../domain/vault_name_utils.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppSettings? _draft;
  bool _saving = false;
  bool _checkingBreaches = false;

  Future<void> _apply() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);
    await ref.read(settingsControllerProvider.notifier).saveSettings(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    TopRightNotification.show(
      context,
      message: 'Settings applied.',
      type: TopRightNotificationType.success,
    );
  }

  void _discard(AppSettings settings) {
    setState(() => _draft = settings);
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load settings.')),
        data: (settings) {
          _draft ??= settings;
          final draft = _draft!;
          final activeVault = draft.activeVaultOrNull;
          if (activeVault == null) {
            return const Center(child: Text('No vault configured.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme follows your preference until you apply.',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<ThemeMode>(
                          key: ValueKey(draft.themeMode),
                          initialValue: draft.themeMode,
                          decoration: const InputDecoration(
                            labelText: 'Theme',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System default'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => _draft = draft.copyWith(themeMode: value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SectionHeader(
                  icon: Icons.security_rounded,
                  title: 'Security',
                  subtitle: 'Biometrics and automatic lock.',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: draft.biometricEnabled,
                          title: const Text('Biometric unlock'),
                          subtitle: const Text(
                            'Confirm identity before entering the master password.',
                          ),
                          onChanged: (value) => setState(
                            () => _draft =
                                draft.copyWith(biometricEnabled: value),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonFormField<int>(
                            key: ValueKey(draft.autoLockTimeout),
                            initialValue: draft.autoLockTimeout,
                            decoration: const InputDecoration(
                              labelText: 'Auto-lock after (minutes)',
                            ),
                            items: const [1, 3, 5, 10, 15]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v min'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _draft =
                                  draft.copyWith(autoLockTimeout: value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SectionHeader(
                  icon: Icons.content_paste_go_outlined,
                  title: 'Clipboard',
                  subtitle: 'Clear copied passwords automatically.',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: draft.clipboardClearEnabled,
                          title: const Text('Auto-clear clipboard'),
                          onChanged: (value) => setState(
                            () => _draft =
                                draft.copyWith(clipboardClearEnabled: value),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonFormField<int>(
                            key: ValueKey(draft.clipboardClearDuration),
                            initialValue: draft.clipboardClearDuration,
                            decoration: const InputDecoration(
                              labelText: 'Clear after (seconds)',
                            ),
                            items: const [10, 15, 30, 60]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v s'),
                                  ),
                                )
                                .toList(),
                            onChanged: draft.clipboardClearEnabled
                                ? (value) => setState(
                                      () => _draft = draft.copyWith(
                                        clipboardClearDuration: value,
                                      ),
                                    )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SectionHeader(
                  icon: Icons.key_outlined,
                  title: 'Active vault',
                  subtitle: 'Hint is shown on unlock after a failed attempt.',
                ),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: const Icon(Icons.vpn_key_outlined, size: 20),
                    ),
                    title: const Text('Password hint'),
                    subtitle: Text(
                      activeVault.passwordHint.isEmpty
                          ? 'No hint set'
                          : activeVault.passwordHint,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SectionHeader(
                  icon: Icons.folder_special_outlined,
                  title: 'Vault & safety',
                  subtitle: 'Export, import, and breach checks for this vault.',
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.password_rounded),
                        title: const Text('Change master password'),
                        subtitle: const Text('Or update hint only'),
                        trailing: FilledButton.tonal(
                          onPressed: _showChangeMasterPasswordDialog,
                          child: const Text('Change'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.upload_file_outlined),
                        title: const Text('Export encrypted vault'),
                        trailing: FilledButton.tonal(
                          onPressed: () => _exportVault(activeVault),
                          child: const Text('Export'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.download_outlined),
                        title: const Text('Import vault file'),
                        trailing: FilledButton.tonal(
                          onPressed: () => _importVault(activeVault),
                          child: const Text('Import'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('Check passwords against breaches'),
                        subtitle: Text(
                          draft.lastBreachCheck == null
                              ? 'Never checked'
                              : 'Last: ${draft.lastBreachCheck!.toLocal()}',
                        ),
                        trailing: FilledButton.icon(
                          onPressed:
                              _checkingBreaches ? null : _checkForBreaches,
                          icon: _checkingBreaches
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            _checkingBreaches ? 'Checking…' : 'Run check',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: settingsState.maybeWhen(
        data: (settings) {
          return Material(
            elevation: 4,
            surfaceTintColor: scheme.surfaceTint,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _discard(settings),
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving ? null : _apply,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Future<void> _checkForBreaches() async {
    setState(() => _checkingBreaches = true);

    try {
      final compromisedCount =
          await ref.read(vaultControllerProvider.notifier).runBreachScan();
      if (!mounted) return;

      final refreshed = ref.read(settingsControllerProvider).valueOrNull;
      if (refreshed != null) {
        setState(() => _draft = refreshed);
      }

      if (compromisedCount < 0) {
        TopRightNotification.show(
          context,
          message: 'Breach check failed. Please try again later.',
          type: TopRightNotificationType.error,
        );
      } else if (compromisedCount > 0) {
        TopRightNotification.show(
          context,
          message:
              'Breach check complete: $compromisedCount compromised account(s) found.',
          type: TopRightNotificationType.warning,
          duration: const Duration(seconds: 4),
        );
      } else {
        TopRightNotification.show(
          context,
          message: 'No compromised passwords found in this vault.',
          type: TopRightNotificationType.success,
        );
      }
    } catch (_) {
      if (!mounted) return;
      TopRightNotification.show(
        context,
        message: 'Breach check failed. Please try again.',
        type: TopRightNotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _checkingBreaches = false);
      }
    }
  }

  Future<void> _exportVault(AppVault vault) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export encrypted vault',
      fileName: '${vault.name.replaceAll(' ', '_')}.dat',
    );
    if (path == null) return;

    try {
      await ref.read(exportVaultUseCaseProvider).call(
            vaultId: vault.id,
            vaultFileName: vault.fileName,
            targetPath: path,
          );
      if (mounted) {
        TopRightNotification.show(
          context,
          message: 'Vault exported successfully.',
          type: TopRightNotificationType.success,
        );
      }
    } catch (_) {
      if (!mounted) return;
      TopRightNotification.show(
        context,
        message: 'Vault export failed.',
        type: TopRightNotificationType.error,
      );
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
        content: const Text(
            'Overwrite active vault? Choose cancel to add as new vault.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel')),
          OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Add new')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Overwrite')),
        ],
      ),
    );

    if (overwrite == null) return;

    late final VaultMetadata peeked;
    try {
      peeked =
          await ref.read(peekVaultMetadataUseCaseProvider).call(sourcePath);
    } catch (_) {
      if (!mounted) return;
      TopRightNotification.show(
        context,
        message: 'Could not read vault file.',
        type: TopRightNotificationType.error,
      );
      return;
    }

    final settingsList =
        ref.read(settingsControllerProvider).valueOrNull?.vaults ?? [];
    final targetFileName = VaultNameUtils.fileNameForDisplayName(peeked.name);

    if (!overwrite) {
      if (VaultNameUtils.isNameTaken(settingsList, peeked.name)) {
        if (!mounted) return;
        TopRightNotification.show(
          context,
          message: 'This vault already exists.',
          type: TopRightNotificationType.error,
        );
        return;
      }
    }

    final vaultId = overwrite
        ? activeVault.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final destFileName = overwrite ? activeVault.fileName : targetFileName;

    try {
      final metadata = await ref.read(importVaultUseCaseProvider).call(
            vaultId: vaultId,
            vaultFileName: destFileName,
            sourcePath: sourcePath,
          );
      if (!overwrite) {
        await ref.read(settingsControllerProvider.notifier).upsertVault(
              AppVault(
                id: vaultId,
                name: metadata.name,
                passwordHint: metadata.hint,
                createdAt: metadata.createdAt,
                fileName: destFileName,
              ),
            );
      } else {
        await ref.read(settingsControllerProvider.notifier).upsertVault(
              activeVault.copyWith(
                name: metadata.name,
                passwordHint: metadata.hint,
                createdAt: metadata.createdAt,
              ),
            );
      }
      if (mounted) {
        TopRightNotification.show(
          context,
          message: 'Vault import complete.',
          type: TopRightNotificationType.success,
        );
      }
    } catch (_) {
      if (!mounted) return;
      TopRightNotification.show(
        context,
        message: 'Vault import failed.',
        type: TopRightNotificationType.error,
      );
    }
  }

  Future<void> _showChangeMasterPasswordDialog() async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();
    final hintController = TextEditingController(
      text: ref
              .read(settingsControllerProvider)
              .valueOrNull
              ?.activeVaultOrNull
              ?.passwordHint ??
          '',
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
                    onChanged: (value) =>
                        setStateDialog(() => hintOnly = value),
                    title: const Text('Change password hint only'),
                  ),
                  if (!hintOnly) ...[
                    TextFormField(
                      controller: currentController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Current Password'),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: nextController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'New Password'),
                      validator: (value) =>
                          PasswordStrengthValidator.validate(value ?? ''),
                    ),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Confirm New Password'),
                      validator: (value) => value != nextController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                  ],
                  TextFormField(
                    controller: hintController,
                    decoration:
                        const InputDecoration(labelText: 'Password hint'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
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
                            await ref
                                .read(vaultControllerProvider.notifier)
                                .changeMasterPassword(
                                  currentPassword: currentController.text,
                                  newPassword: nextController.text,
                                );
                          }
                          final settings =
                              ref.read(settingsControllerProvider).valueOrNull;
                          final av = settings?.activeVaultOrNull;
                          if (settings != null && av != null) {
                            final updatedVault = av.copyWith(
                                passwordHint: hintController.text.trim());
                            await ref
                                .read(updateVaultMetadataUseCaseProvider)
                                .call(
                                  vaultId: updatedVault.id,
                                  vaultFileName: updatedVault.fileName,
                                  metadata: VaultMetadata(
                                    name: updatedVault.name,
                                    hint: updatedVault.passwordHint,
                                    createdAt: updatedVault.createdAt,
                                  ),
                                );
                            await ref
                                .read(settingsControllerProvider.notifier)
                                .upsertVault(updatedVault);
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } on WrongPasswordException {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Current password is incorrect.')),
                          );
                          setStateDialog(() => busy = false);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Unable to update password/hint.')),
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
