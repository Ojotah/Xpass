import '../../../../core/security/breach_checker.dart';

class CheckPasswordBreach {
  const CheckPasswordBreach(this._breachChecker);

  final BreachChecker _breachChecker;

  Future<bool> call(String password) {
    return _breachChecker.isPasswordCompromised(password);
  }
}
