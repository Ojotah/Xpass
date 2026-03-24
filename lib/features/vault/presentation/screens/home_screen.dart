import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../vault_switching/presentation/screens/vault_selection_screen.dart';
import '../providers/vault_providers.dart';
import 'account_details_screen.dart';
import 'add_account_screen.dart';
import 'lock_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
          title: Text(settings?.activeVault.name ?? 'Vault Accounts'),
          actions: [
            IconButton(
              tooltip: 'Vaults',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const VaultSelectionScreen()),
                );
              },
              icon: const Icon(Icons.folder_copy_outlined),
            ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      settings?.activeVault.name ?? 'Vault Accounts',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by title or username',
                    ),
                    onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  Expanded(
                    child: data.accounts.isEmpty
                        ? const Center(child: Text('No accounts yet. Add your first account.'))
                        : filteredAccounts.isEmpty
                            ? const Center(child: Text('No accounts found.'))
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: GridView.builder(
                                  key: ValueKey('accounts-grid-${filteredAccounts.length}'),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.6,
                                  ),
                                  itemCount: filteredAccounts.length,
                                  itemBuilder: (context, index) {
                                    final account = filteredAccounts[index];
                                    final originalIndex = data.accounts.indexOf(account);
                                    return Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
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
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.lock_person_outlined),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      account.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                account.username,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                account.note.trim().isEmpty ? 'No note' : account.note,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
