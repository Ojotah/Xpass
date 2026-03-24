import '../repositories/vault_repository.dart';

class InitializeVault {
  const InitializeVault(this._repository);

  final VaultRepository _repository;

  Future<void> call({required String masterPassword}) {
    return _repository.initializeVault(masterPassword: masterPassword);
  }
}
