import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local_vault_datasource.dart';
import '../../data/repositories/local_vault_repository.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../domain/usecases/add_account.dart';
import '../../domain/usecases/get_accounts.dart';

final localVaultDataSourceProvider = Provider<LocalVaultDataSource>((ref) {
  return LocalVaultDataSource();
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return LocalVaultRepository(ref.watch(localVaultDataSourceProvider));
});

final getAccountsUseCaseProvider = Provider<GetAccounts>((ref) {
  return GetAccounts(ref.watch(vaultRepositoryProvider));
});

final addAccountUseCaseProvider = Provider<AddAccount>((ref) {
  return AddAccount(ref.watch(vaultRepositoryProvider));
});

final vaultUnlockedProvider = StateProvider<bool>((_) => false);

class AccountNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() {
    return ref.read(getAccountsUseCaseProvider).call();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(getAccountsUseCaseProvider).call());
  }

  Future<void> add(Account account) async {
    await ref.read(addAccountUseCaseProvider).call(account);
    await reload();
  }
}

final accountListProvider = AsyncNotifierProvider<AccountNotifier, List<Account>>(
  AccountNotifier.new,
);
