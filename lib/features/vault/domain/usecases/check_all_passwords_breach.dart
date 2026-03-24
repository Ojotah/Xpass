import '../../../../core/security/breach_cache.dart';
import '../../../../core/security/breach_checker.dart';
import '../entities/account.dart';

class CheckAllPasswordsBreach {
  const CheckAllPasswordsBreach({
    required BreachChecker breachChecker,
    required BreachCache breachCache,
  })  : _breachChecker = breachChecker,
        _breachCache = breachCache;

  final BreachChecker _breachChecker;
  final BreachCache _breachCache;

  Future<List<Account>> call(List<Account> accounts) async {
    if (accounts.isEmpty) {
      return const <Account>[];
    }

    final kChecker = _breachChecker as KAnonymityBreachChecker;

    final accountHashes = <int, String>{};
    for (var i = 0; i < accounts.length; i++) {
      accountHashes[i] = await kChecker.sha1Hex(accounts[i].password);
    }

    final hashSet = accountHashes.values.toSet();
    final cachedResults = _breachCache.getMany(hashSet);
    final unresolved = hashSet.where((hash) => !cachedResults.containsKey(hash)).toSet();

    final resolvedFromApi = await kChecker.checkSha1Hashes(unresolved);
    _breachCache.putMany(resolvedFromApi);

    final allResults = <String, bool>{
      ...cachedResults,
      ...resolvedFromApi,
    };

    final updated = <Account>[];
    for (var i = 0; i < accounts.length; i++) {
      final hash = accountHashes[i]!;
      final compromised = allResults[hash] ?? false;
      updated.add(accounts[i].copyWith(isCompromised: compromised));
    }

    return updated;
  }
}
