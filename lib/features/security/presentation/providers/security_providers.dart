import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/services/local_biometric_security_repository.dart';
import '../../domain/repositories/security_repository.dart';
import '../../domain/usecases/authenticate_biometric.dart';

final localAuthenticationProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return LocalBiometricSecurityRepository(
      ref.watch(localAuthenticationProvider));
});

final authenticateBiometricUseCaseProvider =
    Provider<AuthenticateBiometric>((ref) {
  return AuthenticateBiometric(ref.watch(securityRepositoryProvider));
});
