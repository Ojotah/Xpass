import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../vault_switching/presentation/screens/vault_selection_screen.dart';
import '../providers/vault_providers.dart';
import '../widgets/account_password_card.dart';
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
  late final ProviderSubscription<AsyncValue<VaultState>> _vaultStateListener;

  @override
  void initState() {
    super.initState();
    _vaultStateListener =
        ref.listenManual(vaultControllerProvider, (previous, next) {
      final wasUnlocked = previous?.valueOrNull?.isUnlocked ?? false;
      final isUnlocked = next.valueOrNull?.isUnlocked ?? false;
      if (wasUnlocked && !isUnlocked && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LockScreen.routeName,
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _vaultStateListener.close();
    super.dispose();
  }

  Color _riskColor(BuildContext context, int riskScore) {
    final scheme = Theme.of(context).colorScheme;
    if (riskScore >= 70) {
      return scheme.error;
    }
    if (riskScore >= 30) {
      return Colors.orange;
    }
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultControllerProvider);
    final filteredAccounts = ref.watch(filteredAccountsProvider);
    final settings = ref.watch(settingsControllerProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () =>
          ref.read(vaultControllerProvider.notifier).registerInteraction(),
      onPanDown: (_) =>
          ref.read(vaultControllerProvider.notifier).registerInteraction(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accounts'),
          actions: [
            IconButton(
              tooltip: 'Vaults',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const VaultSelectionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.folder_copy_outlined),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
            IconButton(
              tooltip: 'Lock Vault',
              onPressed: () =>
                  ref.read(vaultControllerProvider.notifier).lock(),
              icon: const Icon(Icons.lock_outline),
            ),
          ],
        ),
        body: vaultState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong. Lock and unlock the vault to try again.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final vaultTitle = settings?.activeVaultOrNull?.name ?? 'Vault';

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    vaultTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.accounts.length} saved ${data.accounts.length == 1 ? 'entry' : 'entries'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search by title or username',
                    ),
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).state = value,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: data.accounts.isEmpty
                        ? _EmptyAccountsState(scheme: scheme)
                        : filteredAccounts.isEmpty
                            ? _NoSearchResultsState(scheme: scheme)
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: GridView.builder(
                                  key: ValueKey(
                                    'grid-${filteredAccounts.length}',
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 380,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.75,
                                  ),
                                  itemCount: filteredAccounts.length,
                                  itemBuilder: (context, index) {
                                    final account = filteredAccounts[index];
                                    final originalIndex =
                                        data.accounts.indexOf(account);
                                    final riskColor =
                                        _riskColor(context, account.riskScore);

                                    return AccountPasswordCard(
                                      account: account,
                                      riskColor: riskColor,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          PageRouteBuilder<void>(
                                            pageBuilder: (_, __, ___) =>
                                                AccountDetailsScreen(
                                              index: originalIndex,
                                              account: account,
                                            ),
                                            transitionsBuilder:
                                                (_, animation, __, child) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                            transitionDuration: const Duration(
                                              milliseconds: 220,
                                            ),
                                          ),
                                        );
                                      },
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AddAccountScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
        ),
      ),
    );
  }
}

class _EmptyAccountsState extends StatelessWidget {
  const _EmptyAccountsState({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.password_rounded,
              size: 56,
              color: scheme.primary.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 20),
            Text(
              'No accounts yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first password entry with the button below.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsState extends StatelessWidget {
  const _NoSearchResultsState({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'No matching accounts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search term.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
