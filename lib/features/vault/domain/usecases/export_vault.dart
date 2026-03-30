import 'dart:io';

import '../repositories/vault_repository.dart';

class ExportVault {
  const ExportVault(this._repository);

  final VaultRepository _repository;

  Future<File> call({
    required String vaultId,
    required String vaultFileName,
    required String targetPath,
  }) {
    return _repository.exportVault(
      vaultId: vaultId,
      vaultFileName: vaultFileName,
      targetPath: targetPath,
    );
  }
}
