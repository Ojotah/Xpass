import '../entities/vault_metadata.dart';
import '../repositories/vault_repository.dart';

class UpdateVaultMetadata {
  const UpdateVaultMetadata(this._repository);

  final VaultRepository _repository;

  Future<void> call({
    required String vaultId,
    required String vaultFileName,
    required VaultMetadata metadata,
  }) {
    return _repository.updateVaultMetadata(
      vaultId: vaultId,
      vaultFileName: vaultFileName,
      metadata: metadata,
    );
  }
}
