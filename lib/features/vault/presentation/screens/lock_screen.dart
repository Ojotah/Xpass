import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
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

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    FocusScope.of(context).unfocus();

    await ref.read(vaultControllerProvider.notifier).unlock(_passwordController.text);

    if (!mounted) return;

    final nextState = ref.read(vaultControllerProvider);
    if (nextState.hasError) {
      final error = nextState.error;
      final message = switch (error) {
        WrongPasswordException() => 'Wrong master password.',
        FileCorruptedException() => 'Vault file is corrupted.',
        VaultException() => error.message,
        _ => 'Unable to unlock vault.',
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final unlocked = nextState.valueOrNull?.isUnlocked ?? false;
    if (unlocked) {
      _passwordController.clear();
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultControllerProvider);
    final isBusy = vaultState.isLoading;
    final passwordHint =
        ref.watch(settingsControllerProvider).valueOrNull?.passwordHint.trim() ?? '';

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
                  'Unlock Vault',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
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
                if (passwordHint.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Hint: $passwordHint',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
