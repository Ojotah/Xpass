import '../entities/account.dart';

abstract class VaultRepository {
  /// In the future this method will validate encrypted credentials.
  Future<bool> unlockVault(String masterPassword);

  Future<List<Account>> getAccounts();

  Future<void> addAccount(Account account);
}
