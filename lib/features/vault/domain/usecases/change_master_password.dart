import '../repositories/vault_repository.dart';

class ChangeMasterPassword {
  const ChangeMasterPassword(this._repository);

  final VaultRepository _repository;

  Future<void> call({
    required String vaultId,
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changeMasterPassword(
      vaultId: vaultId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
