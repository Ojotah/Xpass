import '../entities/vault_metadata.dart';
import '../repositories/vault_repository.dart';

class RenameVault {
  const RenameVault(this._repository);

  final VaultRepository _repository;

  Future<void> call({
    required String vaultId,
    required String oldFileName,
    required String newFileName,
    required VaultMetadata metadata,
  }) {
    return _repository.renameVault(
      vaultId: vaultId,
      oldFileName: oldFileName,
      newFileName: newFileName,
      metadata: metadata,
    );
  }
}
