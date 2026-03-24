import '../entities/account.dart';
import '../repositories/vault_repository.dart';

class SaveVault {
  const SaveVault(this._repository);

  final VaultRepository _repository;

  Future<void> call(List<Account> accounts, String masterPassword) {
    return _repository.saveVault(accounts, masterPassword);
  }
}
