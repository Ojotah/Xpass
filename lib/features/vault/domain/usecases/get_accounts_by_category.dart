import '../entities/account.dart';
import '../entities/account_category.dart';
import 'detect_account_category.dart';

class GetAccountsByCategory {
  const GetAccountsByCategory(this._detectAccountCategory);

  final DetectAccountCategory _detectAccountCategory;

  List<Account> call(List<Account> accounts, AccountCategory category) {
    if (category == AccountCategory.all) {
      return accounts;
    }

    return accounts
        .where((account) => _detectAccountCategory.call(account) == category)
        .toList(growable: false);
  }
}
