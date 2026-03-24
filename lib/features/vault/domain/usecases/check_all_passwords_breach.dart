import '../entities/account.dart';
import 'check_password_breach.dart';

class CheckAllPasswordsBreach {
  const CheckAllPasswordsBreach(this._checkPasswordBreach);

  final CheckPasswordBreach _checkPasswordBreach;

  Future<List<Account>> call(List<Account> accounts) async {
    final cache = <String, bool>{};
    final updated = <Account>[];

    for (final account in accounts) {
      final cached = cache[account.password];
      final compromised =
          cached ?? await _checkPasswordBreach.call(account.password);
      cache[account.password] = compromised;
      updated.add(account.copyWith(isCompromised: compromised));
    }

    return updated;
  }
}
