import 'dart:io';

import '../entities/account.dart';
import '../entities/vault_metadata.dart';

abstract class VaultRepository {
  Future<bool> vaultExists(String vaultFileName);

  Future<void> initializeVault({
    required String vaultId,
    required String vaultFileName,
    required String masterPassword,
    required VaultMetadata metadata,
  });

  Future<List<Account>> unlockVault({
    required String vaultId,
    required String vaultFileName,
    required String masterPassword,
  });

  Future<void> saveVault({
    required String vaultId,
    required String vaultFileName,
    required List<Account> accounts,
    required String masterPassword,
  });

  Future<void> changeMasterPassword({
    required String vaultId,
    required String vaultFileName,
    required String currentPassword,
    required String newPassword,
  });

  Future<File> exportVault({
    required String vaultId,
    required String vaultFileName,
    required String targetPath,
  });

  Future<VaultMetadata> importVault({
    required String vaultId,
    required String vaultFileName,
    required String sourcePath,
  });

  /// Reads vault metadata from an external file without copying it into app storage.
  Future<VaultMetadata> peekMetadataFromImportPath(String sourcePath);

  Future<void> renameVault({
    required String vaultId,
    required String oldFileName,
    required String newFileName,
    required VaultMetadata metadata,
  });

  Future<void> updateVaultMetadata({
    required String vaultId,
    required String vaultFileName,
    required VaultMetadata metadata,
  });

  Future<void> deleteVault(
      {required String vaultId, required String vaultFileName});
}
