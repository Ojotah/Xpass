import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

abstract class BreachChecker {
  Future<bool> isPasswordCompromised(String password);
}

class KAnonymityBreachChecker implements BreachChecker {
  KAnonymityBreachChecker({
    HttpClient? httpClient,
    this.endpointBase = 'https://api.pwnedpasswords.com/range/',
    this.requestDelay = const Duration(milliseconds: 120),
  }) : _httpClient = httpClient;

  final HttpClient? _httpClient;
  final String endpointBase;
  final Duration requestDelay;

  @override
  Future<bool> isPasswordCompromised(String password) async {
    if (password.isEmpty) {
      return false;
    }

    final hashHex = await sha1Hex(password);
    final grouped = await checkSha1Hashes(<String>{hashHex});
    return grouped[hashHex] ?? false;
  }

  Future<String> sha1Hex(String value) async {
    final hash = await Sha1().hash(utf8.encode(value));
    final buffer = StringBuffer();
    for (final byte in hash.bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString().toUpperCase();
  }

  Future<Map<String, bool>> checkSha1Hashes(Iterable<String> hashes) async {
    final pending = hashes.where((value) => value.isNotEmpty).toSet();
    if (pending.isEmpty) {
      return const <String, bool>{};
    }

    final groupedByPrefix = <String, List<String>>{};
    for (final hash in pending) {
      final prefix = hash.substring(0, 5);
      groupedByPrefix.putIfAbsent(prefix, () => <String>[]).add(hash.substring(5));
    }

    final resolved = <String, bool>{};

    for (final group in groupedByPrefix.entries) {
      final response = await _queryHashRange(group.key);
      final suffixHits = _parseResponseToCounts(response);

      for (final suffix in group.value) {
        final fullHash = '${group.key}$suffix';
        resolved[fullHash] = (suffixHits[suffix] ?? 0) > 0;
      }
    }

    return resolved;
  }

  Map<String, int> _parseResponseToCounts(String response) {
    final lines = const LineSplitter().convert(response);
    final counts = <String, int>{};

    for (final line in lines) {
      final parts = line.split(':');
      if (parts.length != 2) {
        continue;
      }
      final suffix = parts.first.trim().toUpperCase();
      final count = int.tryParse(parts.last.trim()) ?? 0;
      counts[suffix] = count;
    }

    return counts;
  }

  Future<String> _queryHashRange(String hashPrefix) async {
    final client = _httpClient ?? HttpClient();
    final uri = Uri.parse('$endpointBase$hashPrefix');
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, 'XPass/1.0');

    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Breach check request failed with status ${response.statusCode}.',
        uri: uri,
      );
    }

    final payload = await response.transform(utf8.decoder).join();
    if (requestDelay > Duration.zero) {
      await Future<void>.delayed(requestDelay);
    }
    return payload;
  }
}
