import 'package:flutter_test/flutter_test.dart';
import 'package:xpass/features/vault/domain/usecases/calculate_password_risk.dart';

void main() {
  test('caps risk score at 100', () {
    const useCase = CalculatePasswordRisk();

    final score = useCase(
      isCompromised: true,
      isWeak: true,
      isReused: true,
    );

    expect(score, 100);
  });
}
