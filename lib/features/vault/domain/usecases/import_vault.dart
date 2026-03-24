import '../repositories/vault_repository.dart';

class ImportVault {
  const ImportVault(this._repository);

  final VaultRepository _repository;

  Future<void> call({required String vaultId, required String sourcePath}) {
    return _repository.importVault(vaultId: vaultId, sourcePath: sourcePath);
  }
}
