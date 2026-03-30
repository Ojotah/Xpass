import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_handler.dart';
import '../../../security/presentation/providers/security_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../vault_switching/presentation/screens/startup_vault_selection_screen.dart';
import '../providers/vault_providers.dart';
import 'home_screen.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  static const routeName = '/lock';

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _passwordController = TextEditingController();
  bool _biometricTried = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_biometricTried) {
      _biometricTried = true;
      _tryBiometricUnlock();
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final settings = ref.read(settingsControllerProvider).valueOrNull;
    if (settings == null || !settings.biometricEnabled) {
      return;
    }

    final authenticated =
        await ref.read(authenticateBiometricUseCaseProvider).call();
    if (!authenticated || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Biometric verification complete. Enter password to unlock.')),
    );
  }

  Future<void> _unlock() async {
    FocusScope.of(context).unfocus();

    await ref
        .read(vaultControllerProvider.notifier)
        .unlock(_passwordController.text);

    if (!mounted) return;

    final nextState = ref.read(vaultControllerProvider);
    if (nextState.hasError) {
      final error = nextState.error;
      final message = error == null
          ? 'Unable to unlock vault.'
          : ErrorHandler.toUserMessage(error);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final unlocked = nextState.valueOrNull?.isUnlocked ?? false;
    if (unlocked) {
      _passwordController.clear();
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    }
  }

  Future<void> _chooseAnotherVault() async {
    _passwordController.clear();
    final settings = ref.read(settingsControllerProvider).valueOrNull;
    if (settings == null) {
      return;
    }

    await ref.read(vaultControllerProvider.notifier).switchVault();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StartupVaultSelectionScreen(vaults: settings.vaults),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultControllerProvider);
    final isBusy = vaultState.isLoading;
    final activeVault =
        ref.watch(settingsControllerProvider).valueOrNull?.activeVault;
    final vaultName = activeVault?.name ?? 'Vault';
    final passwordHint = activeVault?.passwordHint ?? '';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Unlock $vaultName',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if (passwordHint.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Hint: $passwordHint',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Master Password',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isBusy ? null : _unlock,
                  child: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : _chooseAnotherVault,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Choose another vault'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
