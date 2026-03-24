import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/password_strength_validator.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/entities/app_vault.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
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
    final vault = AppVault(
      id: 'default',
      name: _vaultNameController.text.trim(),
      passwordHint: _hintController.text.trim(),
    );
    final settings = AppSettings.defaults.copyWith(
      activeVaultId: vault.id,
      vaults: [vault],
    );

    try {
      await ref.read(vaultControllerProvider.notifier).initialize(password);
      await ref.read(settingsControllerProvider.notifier).saveSettings(settings);

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
          title: const Text('Import Existing Vault'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Master Password'),
              ),
              TextField(
                controller: hintController,
                decoration: const InputDecoration(labelText: 'Password Hint (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((passwordController.text, hintController.text.trim())),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      passwordController.dispose();
      hintController.dispose();

      if (imported == null) return;

      await ref.read(importVaultUseCaseProvider).call(vaultId: 'default', sourcePath: sourcePath);
      await ref.read(vaultControllerProvider.notifier).unlock(imported.$1);

      final nextState = ref.read(vaultControllerProvider);
      if (nextState.hasError) {
        throw nextState.error ?? const VaultException('Unable to unlock imported vault.');
      }

      final settings = AppSettings.defaults.copyWith(
        vaults: [
          AppVault(id: 'default', name: 'Imported Vault', passwordHint: imported.$2 ?? ''),
        ],
      );
      await ref.read(settingsControllerProvider.notifier).saveSettings(settings);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } on WrongPasswordException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid password for imported vault.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Your Vault',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your encrypted vault to get started.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _vaultNameController,
                    decoration: const InputDecoration(
                      labelText: 'Vault Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vault name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _masterPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Master Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Master password is required.';
                      }
                      return PasswordStrengthValidator.validate(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Master Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != _masterPasswordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hintController,
                    decoration: const InputDecoration(
                      labelText: 'Password Hint (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isBusy ? null : _initialize,
                    child: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Vault'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _importExistingVault,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Import Existing Vault'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
