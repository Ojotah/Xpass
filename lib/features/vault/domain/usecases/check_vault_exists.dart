import '../repositories/vault_repository.dart';

class CheckVaultExists {
  const CheckVaultExists(this._repository);

  final VaultRepository _repository;

  Future<bool> call(String vaultId) => _repository.vaultExists(vaultId);
}
