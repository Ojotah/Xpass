import 'package:local_auth/local_auth.dart';

import '../../domain/repositories/security_repository.dart';

class LocalBiometricSecurityRepository implements SecurityRepository {
  LocalBiometricSecurityRepository(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  @override
  Future<bool> authenticateWithBiometric() async {
    return _auth.authenticate(
      localizedReason: 'Authenticate to unlock your vault',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
  }
}
