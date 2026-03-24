import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vault_providers.dart';
import '../widgets/account_list_tile.dart';
import 'add_account_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vault Accounts')),
      body: accountState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              return AccountListTile(account: accounts[index]);
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
