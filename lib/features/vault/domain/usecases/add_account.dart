import '../entities/account.dart';
import '../repositories/vault_repository.dart';

class AddAccount {
  const AddAccount(this._repository);

  final VaultRepository _repository;

  Future<void> call(Account account) => _repository.addAccount(account);
}
