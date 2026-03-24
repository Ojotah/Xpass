class PasswordStrengthValidator {
  const PasswordStrengthValidator._();

  static String? validate(String value) {
    if (value.length < 10) {
      return 'Use at least 10 characters.';
    }

    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasLower = value.contains(RegExp(r'[a-z]'));
    final hasNumber = value.contains(RegExp(r'[0-9]'));

    if (!hasUpper || !hasLower || !hasNumber) {
      return 'Include upper, lower, and numeric characters.';
    }

    return null;
  }
}
