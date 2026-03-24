import '../entities/account.dart';
import 'check_password_breach.dart';

class UpdatePasswordSecurityStatus {
  const UpdatePasswordSecurityStatus(this._checkPasswordBreach);

  final CheckPasswordBreach _checkPasswordBreach;

  Future<List<Account>> call(List<Account> accounts) async {
    final updated = <Account>[];

    for (final account in accounts) {
      final compromised = await _checkPasswordBreach.call(account.password);
      updated.add(account.copyWith(isCompromised: compromised));
    }

    return updated;
  }
}
