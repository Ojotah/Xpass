import '../entities/account.dart';
import '../repositories/vault_repository.dart';

class SaveVault {
  const SaveVault(this._repository);

  final VaultRepository _repository;

  Future<void> call({
    required String vaultId,
    required List<Account> accounts,
    required String masterPassword,
  }) {
    return _repository.saveVault(
      vaultId: vaultId,
      accounts: accounts,
      masterPassword: masterPassword,
    );
  }
}
