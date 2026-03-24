import '../entities/account.dart';
import '../repositories/vault_repository.dart';

class UnlockVault {
  const UnlockVault(this._repository);

  final VaultRepository _repository;

  Future<List<Account>> call({required String vaultId, required String masterPassword}) {
    return _repository.unlockVault(vaultId: vaultId, masterPassword: masterPassword);
  }
}
