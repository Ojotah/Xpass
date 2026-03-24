import 'dart:io';

import '../entities/account.dart';

abstract class VaultRepository {
  Future<bool> vaultExists(String vaultId);

  Future<void> initializeVault({
    required String vaultId,
    required String masterPassword,
  });

  Future<List<Account>> unlockVault({
    required String vaultId,
    required String masterPassword,
  });

  Future<void> saveVault({
    required String vaultId,
    required List<Account> accounts,
    required String masterPassword,
  });

  Future<void> changeMasterPassword({
    required String vaultId,
    required String currentPassword,
    required String newPassword,
  });

  Future<File> exportVault({
    required String vaultId,
    required String targetPath,
  });

  Future<void> importVault({
    required String vaultId,
    required String sourcePath,
  });

  Future<void> deleteVault(String vaultId);
}
