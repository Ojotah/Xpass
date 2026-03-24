import '../entities/account.dart';
import '../entities/account_category.dart';

class DetectAccountCategory {
  const DetectAccountCategory();

  AccountCategory call(Account account) {
    final username = account.username.trim().toLowerCase();
    final atIndex = username.lastIndexOf('@');
    if (atIndex < 0 || atIndex == username.length - 1) {
      return AccountCategory.others;
    }

    final domain = username.substring(atIndex + 1);

    if (domain.contains('outlook.') || domain.contains('hotmail.') || domain.contains('live.') || domain.contains('microsoft.')) {
      return AccountCategory.microsoft;
    }

    if (domain.contains('gmail.') || domain.contains('googlemail.') || domain.contains('google.')) {
      return AccountCategory.google;
    }

    if (domain.contains('icloud.') || domain.contains('me.com') || domain.contains('mac.com') || domain.contains('apple.')) {
      return AccountCategory.apple;
    }

    return AccountCategory.others;
  }
}
