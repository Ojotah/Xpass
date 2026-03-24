import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vault_providers.dart';
import '../widgets/account_list_tile.dart';
import 'add_account_screen.dart';
import 'lock_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(vaultControllerProvider, (previous, next) {
      final isUnlocked = next.valueOrNull?.isUnlocked ?? false;
      if (!isUnlocked) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LockScreen.routeName,
          (route) => false,
        );
      }
    });

    final vaultState = ref.watch(vaultControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Accounts'),
        actions: [
          IconButton(
            tooltip: 'Lock Vault',
            onPressed: () => ref.read(vaultControllerProvider.notifier).lock(),
            icon: const Icon(Icons.lock_outline),
          ),
        ],
      ),
      body: vaultState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (data) {
          if (data.accounts.isEmpty) {
            return const Center(child: Text('No accounts yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.accounts.length,
            itemBuilder: (context, index) {
              return AccountListTile(account: data.accounts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddAccountScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
