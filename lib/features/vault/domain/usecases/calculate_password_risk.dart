class CalculatePasswordRisk {
  const CalculatePasswordRisk();

  int call({
    required bool isCompromised,
    required bool isWeak,
    required bool isReused,
  }) {
    var score = 0;
    if (isCompromised) {
      score += 70;
    }
    if (isWeak) {
      score += 20;
    }
    if (isReused) {
      score += 30;
    }

    if (score > 100) {
      return 100;
    }
    return score;
  }
}
