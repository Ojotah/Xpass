import '../repositories/security_repository.dart';

class AuthenticateBiometric {
  const AuthenticateBiometric(this._repository);

  final SecurityRepository _repository;

  Future<bool> call() {
    return _repository.authenticateWithBiometric();
  }
}
