import '../entities/account.dart';

abstract class VaultRepository {
  Future<List<Account>> unlockVault(String masterPassword);

  Future<void> saveVault(List<Account> accounts, String masterPassword);
}
