class DetectWeakPasswords {
  const DetectWeakPasswords();

  bool call(String password) {
    if (password.length < 8) {
      return true;
    }

    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(RegExp(r'[^A-Za-z0-9]'));

    return !(hasUpper && hasLower && hasNumber && hasSymbol);
  }
}
