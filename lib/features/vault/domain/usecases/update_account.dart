import '../entities/account.dart';

class UpdateAccount {
  const UpdateAccount();

  List<Account> call(List<Account> accounts, int index, Account updated) {
    if (index < 0 || index >= accounts.length) {
      return accounts;
    }

    final next = [...accounts]..[index] = updated;
    return next;
  }
}
