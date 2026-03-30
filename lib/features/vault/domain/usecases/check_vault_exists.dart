import '../repositories/vault_repository.dart';

class CheckVaultExists {
  const CheckVaultExists(this._repository);

  final VaultRepository _repository;

  Future<bool> call(String vaultFileName) =>
      _repository.vaultExists(vaultFileName);
}
