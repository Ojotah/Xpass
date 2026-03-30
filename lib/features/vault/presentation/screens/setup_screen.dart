import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/password_strength_validator.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/entities/app_vault.dart';
import '../../../settings/domain/vault_name_utils.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/vault_metadata.dart';
import '../providers/vault_providers.dart';
import 'home_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  static const routeName = '/setup';

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vaultNameController = TextEditingController(text: 'My Vault');
  final _masterPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _hintController = TextEditingController();

  bool _isBusy = false;

  @override
  void dispose() {
    _vaultNameController.dispose();
    _masterPasswordController.dispose();
    _confirmPasswordController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isBusy = true);

    final password = _masterPasswordController.text;
    final vaultName = _vaultNameController.text.trim();
    final existing =
        ref.read(settingsControllerProvider).valueOrNull?.vaults ?? [];
    if (VaultNameUtils.isNameTaken(existing, vaultName)) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A vault with this name already exists.'),
          ),
        );
      }
      return;
    }

    final vaultId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = VaultNameUtils.fileNameForDisplayName(vaultName);
    final vault = AppVault(
      id: vaultId,
      name: vaultName,
      passwordHint: _hintController.text.trim(),
      createdAt: DateTime.now().toUtc(),
      fileName: fileName,
    );
    final settings = AppSettings.defaults.copyWith(
      activeVaultId: vault.id,
      vaults: [vault],
    );

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .saveSettings(settings);
      await ref.read(vaultControllerProvider.notifier).initialize(password);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _importExistingVault() async {
    setState(() => _isBusy = true);
    try {
      final pick = await FilePicker.platform.pickFiles(type: FileType.any);
      final sourcePath = pick?.files.single.path;
      if (sourcePath == null) {
        return;
      }

      if (!mounted) return;
      final passwordController = TextEditingController();
      final hintController = TextEditingController();
      final imported = await showDialog<(String, String?)>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import existing vault'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Master password',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hintController,
                decoration: const InputDecoration(
                  labelText: 'Password hint (optional)',
                  prefixIcon: Icon(Icons.lightbulb_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .pop((passwordController.text, hintController.text.trim())),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      passwordController.dispose();
      hintController.dispose();

      if (imported == null) return;

      VaultMetadata peeked;
      try {
        peeked =
            await ref.read(peekVaultMetadataUseCaseProvider).call(sourcePath);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read vault file.')),
        );
        return;
      }

      final existing =
          ref.read(settingsControllerProvider).valueOrNull?.vaults ?? [];
      if (VaultNameUtils.isNameTaken(existing, peeked.name)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This vault is already imported.'),
          ),
        );
        return;
      }

      final vaultId = DateTime.now().millisecondsSinceEpoch.toString();
      final targetFileName = VaultNameUtils.fileNameForDisplayName(peeked.name);
      final metadata = await ref.read(importVaultUseCaseProvider).call(
            vaultId: vaultId,
            vaultFileName: targetFileName,
            sourcePath: sourcePath,
          );
      await ref.read(vaultControllerProvider.notifier).unlock(imported.$1);

      final nextState = ref.read(vaultControllerProvider);
      if (nextState.hasError) {
        throw nextState.error ??
            const VaultException('Unable to unlock imported vault.');
      }

      final settings = AppSettings.defaults.copyWith(
        activeVaultId: vaultId,
        vaults: [
          AppVault(
            id: vaultId,
            name: metadata.name,
            passwordHint:
                imported.$2?.isNotEmpty == true ? imported.$2! : metadata.hint,
            createdAt: metadata.createdAt,
            fileName: targetFileName,
          ),
        ],
      );
      await ref
          .read(settingsControllerProvider.notifier)
          .saveSettings(settings);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } on WrongPasswordException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load vault')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.lock_person_outlined,
                            size: 52,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to XPass',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create an encrypted vault stored only on this device.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _vaultNameController,
                            decoration: const InputDecoration(
                              labelText: 'Vault name',
                              prefixIcon: Icon(Icons.folder_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vault name is required.';
                              }
                              final vaults = ref
                                      .read(settingsControllerProvider)
                                      .valueOrNull
                                      ?.vaults ??
                                  [];
                              if (VaultNameUtils.isNameTaken(vaults, value)) {
                                return 'This vault name is already used.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _masterPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Master password',
                              prefixIcon: Icon(Icons.key_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Master password is required.';
                              }
                              return PasswordStrengthValidator.validate(value);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm master password',
                              prefixIcon: Icon(Icons.key_off_outlined),
                            ),
                            validator: (value) {
                              if (value != _masterPasswordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _hintController,
                            decoration: const InputDecoration(
                              labelText: 'Password hint (optional)',
                              prefixIcon: Icon(Icons.lightbulb_outline),
                            ),
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: _isBusy ? null : _initialize,
                            child: _isBusy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Create vault'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isBusy ? null : _importExistingVault,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Import existing vault'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
