import '../entities/account.dart';

class SearchAccounts {
  const SearchAccounts();

  List<Account> call(List<Account> accounts, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return accounts;
    }

    return accounts.where((account) {
      return account.title.toLowerCase().contains(normalized) ||
          account.username.toLowerCase().contains(normalized);
    }).toList(growable: false);
  }
}
