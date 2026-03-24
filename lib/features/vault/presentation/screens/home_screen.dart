import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/vault_providers.dart';
import '../widgets/account_list_tile.dart';
import 'account_details_screen.dart';
import 'add_account_screen.dart';
import 'lock_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      ref.read(vaultControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final filteredAccounts = ref.watch(filteredAccountsProvider);
    final settings = ref.watch(settingsControllerProvider).valueOrNull;

    return GestureDetector(
      onTap: () => ref.read(vaultControllerProvider.notifier).registerInteraction(),
      onPanDown: (_) => ref.read(vaultControllerProvider.notifier).registerInteraction(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(settings?.vaultName ?? 'Vault Accounts'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
            IconButton(
              tooltip: 'Lock Vault',
              onPressed: () => ref.read(vaultControllerProvider.notifier).lock(),
              icon: const Icon(Icons.lock_outline),
            ),
          ],
        ),
        body: vaultState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('Something went wrong. Please lock and unlock vault again.'),
          ),
          data: (data) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by title or username',
                    ),
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).state = value,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: data.accounts.isEmpty
                        ? const Center(child: Text('No accounts yet. Add your first account.'))
                        : filteredAccounts.isEmpty
                            ? const Center(child: Text('No accounts found.'))
                            : ListView.builder(
                                itemCount: filteredAccounts.length,
                                itemBuilder: (context, index) {
                                  final account = filteredAccounts[index];
                                  final originalIndex = data.accounts.indexOf(account);
                                  return AccountListTile(
                                    account: account,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => AccountDetailsScreen(
                                            index: originalIndex,
                                            account: account,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
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
      ),
    );
  }
}
