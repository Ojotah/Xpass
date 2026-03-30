import '../entities/vault_metadata.dart';
import '../repositories/vault_repository.dart';

class ImportVault {
  const ImportVault(this._repository);

  final VaultRepository _repository;

  Future<VaultMetadata> call({
    required String vaultId,
    required String vaultFileName,
    required String sourcePath,
  }) {
    return _repository.importVault(
      vaultId: vaultId,
      vaultFileName: vaultFileName,
      sourcePath: sourcePath,
    );
  }
}
