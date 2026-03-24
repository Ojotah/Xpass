abstract class SecurityRepository {
  Future<bool> isBiometricAvailable();

  Future<bool> authenticateWithBiometric();
}
