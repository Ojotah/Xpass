import '../../domain/entities/account.dart';
import '../../domain/repositories/vault_repository.dart';
import '../datasources/local_vault_datasource.dart';
import '../models/account_model.dart';

class LocalVaultRepository implements VaultRepository {
  LocalVaultRepository(this._localDataSource);

  final LocalVaultDataSource _localDataSource;

  @override
  Future<void> addAccount(Account account) async {
    final accounts = await _localDataSource.readAccounts();
    accounts.add(AccountModel.fromEntity(account));
    await _localDataSource.writeAccounts(accounts);
  }

  @override
  Future<List<Account>> getAccounts() => _localDataSource.readAccounts();

  @override
  Future<bool> unlockVault(String masterPassword) async {
    // Placeholder unlock flow. Future implementation should validate a
    // derived key against encrypted vault metadata.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return masterPassword.isNotEmpty;
  }
}
