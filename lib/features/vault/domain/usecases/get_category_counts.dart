import '../entities/account.dart';
import '../entities/account_category.dart';
import 'detect_account_category.dart';

class GetCategoryCounts {
  const GetCategoryCounts(this._detectAccountCategory);

  final DetectAccountCategory _detectAccountCategory;

  Map<AccountCategory, int> call(List<Account> accounts) {
    final counts = {
      AccountCategory.all: accounts.length,
      AccountCategory.microsoft: 0,
      AccountCategory.google: 0,
      AccountCategory.apple: 0,
      AccountCategory.others: 0,
    };

    for (final account in accounts) {
      final category = _detectAccountCategory.call(account);
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return counts;
  }
}
