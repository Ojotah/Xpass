class BreachCache {
  BreachCache({this.ttl = const Duration(days: 3)});

  final Duration ttl;
  final Map<String, _BreachCacheEntry> _entries = <String, _BreachCacheEntry>{};

  bool? get(String sha1Hash) {
    final entry = _entries[sha1Hash];
    if (entry == null) {
      return null;
    }

    final now = DateTime.now().toUtc();
    if (now.difference(entry.checkedAt) > ttl) {
      _entries.remove(sha1Hash);
      return null;
    }

    return entry.isCompromised;
  }

  Map<String, bool> getMany(Iterable<String> sha1Hashes) {
    final resolved = <String, bool>{};
    for (final hash in sha1Hashes) {
      final value = get(hash);
      if (value != null) {
        resolved[hash] = value;
      }
    }
    return resolved;
  }

  void put(String sha1Hash, bool isCompromised) {
    _entries[sha1Hash] = _BreachCacheEntry(
      isCompromised: isCompromised,
      checkedAt: DateTime.now().toUtc(),
    );
  }

  void putMany(Map<String, bool> results) {
    for (final item in results.entries) {
      put(item.key, item.value);
    }
  }
}

class _BreachCacheEntry {
  const _BreachCacheEntry({
    required this.isCompromised,
    required this.checkedAt,
  });

  final bool isCompromised;
  final DateTime checkedAt;
}
