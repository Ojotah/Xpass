import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final autoClear = ref.watch(autoClearClipboardProvider);
    final autoLockMinutes = ref.watch(autoLockMinutesProvider);

    return GestureDetector(
      onTap: () => ref.read(vaultControllerProvider.notifier).registerInteraction(),
      onPanDown: (_) => ref.read(vaultControllerProvider.notifier).registerInteraction(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
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
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: autoClear,
                          title: const Text('Auto-clear clipboard'),
                          subtitle: const Text('Clears copied secrets after 15 seconds'),
                          onChanged: (value) =>
                              ref.read(autoClearClipboardProvider.notifier).state = value,
                        ),
                        ListTile(
                          title: const Text('Auto-lock timeout'),
                          subtitle: Text('$autoLockMinutes minutes of inactivity'),
                          trailing: DropdownButton<int>(
                            value: autoLockMinutes,
                            onChanged: (value) {
                              if (value == null) return;
                              ref.read(autoLockMinutesProvider.notifier).state = value;
                              ref.read(vaultControllerProvider.notifier).registerInteraction();
                            },
                            items: const [1, 3, 5, 10]
                                .map(
                                  (minute) => DropdownMenuItem<int>(
                                    value: minute,
                                    child: Text('$minute min'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
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
