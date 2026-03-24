import '../entities/account.dart';
import '../repositories/vault_repository.dart';

class GetAccounts {
  const GetAccounts(this._repository);

  final VaultRepository _repository;

  Future<List<Account>> call() => _repository.getAccounts();
}
