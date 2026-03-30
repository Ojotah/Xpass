import '../entities/vault_metadata.dart';
import '../repositories/vault_repository.dart';

class PeekVaultMetadata {
  const PeekVaultMetadata(this._repository);

  final VaultRepository _repository;

  Future<VaultMetadata> call(String sourcePath) {
    return _repository.peekMetadataFromImportPath(sourcePath);
  }
}
