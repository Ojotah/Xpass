import '../entities/account.dart';

abstract class VaultRepository {
  Future<bool> vaultExists();

  Future<void> initializeVault({
    required String masterPassword,
  });

  Future<List<Account>> unlockVault(String masterPassword);

  Future<void> saveVault(List<Account> accounts, String masterPassword);

  Future<void> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  });
}
