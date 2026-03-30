import 'package:flutter_test/flutter_test.dart';
import 'package:xpass/core/security/breach_cache.dart';
import 'package:xpass/core/security/breach_checker.dart';
import 'package:xpass/features/vault/domain/entities/account.dart';
import 'package:xpass/features/vault/domain/usecases/check_all_passwords_breach.dart';

void main() {
  test('marks compromised account from hash set lookup', () async {
    final checker =
        KAnonymityBreachChecker(httpClient: null, requestDelay: Duration.zero);

    final useCase = CheckAllPasswordsBreach(
      breachChecker: _FakeKAnonymityBreachChecker(checker),
      breachCache: BreachCache(),
    );

    final accounts = [
      const Account(title: 'A', username: 'u1', password: 'safe-password'),
      const Account(title: 'B', username: 'u2', password: 'pwned-password'),
    ];

    final result = await useCase(accounts);

    expect(result[0].isCompromised, isFalse);
    expect(result[1].isCompromised, isTrue);
  });
}

class _FakeKAnonymityBreachChecker extends KAnonymityBreachChecker {
  _FakeKAnonymityBreachChecker(this._delegate)
      : super(
            endpointBase: 'https://example.invalid/',
            requestDelay: Duration.zero);

  final KAnonymityBreachChecker _delegate;

  @override
  Future<String> sha1Hex(String value) => _delegate.sha1Hex(value);

  @override
  Future<Map<String, bool>> checkSha1Hashes(Iterable<String> hashes) async {
    final resolved = <String, bool>{};
    for (final hash in hashes) {
      resolved[hash] = hash.endsWith('BAD');
    }

    // Deterministic compromise: only this password hash ends with BAD marker.
    final pwned = await _delegate.sha1Hex('pwned-password');
    resolved[pwned] = true;

    return resolved;
  }
}
