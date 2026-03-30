import '../entities/vault_metadata.dart';
import '../repositories/vault_repository.dart';

class InitializeVault {
  const InitializeVault(this._repository);

  final VaultRepository _repository;

  Future<void> call({
    required String vaultId,
    required String vaultFileName,
    required String masterPassword,
    required VaultMetadata metadata,
  }) {
    return _repository.initializeVault(
      vaultId: vaultId,
      vaultFileName: vaultFileName,
      masterPassword: masterPassword,
      metadata: metadata,
    );
  }
}
