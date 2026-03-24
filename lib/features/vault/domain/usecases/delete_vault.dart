import '../repositories/vault_repository.dart';

class DeleteVault {
  const DeleteVault(this._repository);

  final VaultRepository _repository;

  Future<void> call(String vaultId) {
    return _repository.deleteVault(vaultId);
  }
}
