import '../entities/account.dart';

class DeleteAccount {
  const DeleteAccount();

  List<Account> call(List<Account> accounts, int index) {
    if (index < 0 || index >= accounts.length) {
      return accounts;
    }

    final next = [...accounts]..removeAt(index);
    return next;
  }
}
