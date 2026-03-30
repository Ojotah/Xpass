import '../entities/account.dart';

class DetectReusedPasswords {
  const DetectReusedPasswords();

  Set<int> call(List<Account> accounts) {
    final indicesByPassword = <String, List<int>>{};

    for (var i = 0; i < accounts.length; i++) {
      final password = accounts[i].password;
      indicesByPassword.putIfAbsent(password, () => <int>[]).add(i);
    }

    final reusedIndices = <int>{};
    for (final indices in indicesByPassword.values) {
      if (indices.length > 1) {
        reusedIndices.addAll(indices);
      }
    }

    return reusedIndices;
  }
}
