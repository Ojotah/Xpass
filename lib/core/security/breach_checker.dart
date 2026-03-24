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

    final hashHex = await _sha1Hex(password);
    final prefix = hashHex.substring(0, 5);
    final suffix = hashHex.substring(5);

    final response = await _queryHashRange(prefix);
    final lines = const LineSplitter().convert(response);

    for (final line in lines) {
      final parts = line.split(':');
      if (parts.length != 2) {
        continue;
      }

      if (parts.first.trim().toUpperCase() == suffix) {
        final count = int.tryParse(parts.last.trim()) ?? 0;
        return count > 0;
      }
    }

    return false;
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

  Future<String> _sha1Hex(String value) async {
    final hash = await Sha1().hash(utf8.encode(value));
    final buffer = StringBuffer();
    for (final byte in hash.bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString().toUpperCase();
  }
}
