import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../error/exceptions.dart';
import 'encryption_service.dart';

class AesEncryptionService implements EncryptionService {
  AesEncryptionService({
    AesGcm? algorithm,
    Pbkdf2? pbkdf2,
  })  : _algorithm = algorithm ?? AesGcm.with256bits(),
        _pbkdf2 = pbkdf2 ??
            Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: 120000,
              bits: 256,
            );

  final AesGcm _algorithm;
  final Pbkdf2 _pbkdf2;

  /// Use Dart's secure random
  final _secureRandom = Random.secure();

  @override
  Future<String> encrypt(String plainText, String password) async {
    if (password.isEmpty) {
      throw const WrongPasswordException('Master password is required.');
    }

    final salt = _generateBytes(16);
    final nonce = _generateBytes(12);

    final key = await _deriveKey(password, salt);

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );

    final payload = {
      'v': 1,
      'alg': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iter': 120000,
      'salt': base64Encode(salt),
      'nonce': base64Encode(secretBox.nonce),
      'ct': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  @override
  Future<String> decrypt(String cipherText, String password) async {
    if (password.isEmpty) {
      throw const WrongPasswordException('Master password is required.');
    }

    try {
      final decoded = utf8.decode(base64Decode(cipherText));
      final payload = jsonDecode(decoded) as Map<String, dynamic>;

      final salt = base64Decode(payload['salt']);
      final nonce = base64Decode(payload['nonce']);
      final cipher = base64Decode(payload['ct']);
      final mac = Mac(base64Decode(payload['mac']));

      final key = await _deriveKey(password, salt);

      final clear = await _algorithm.decrypt(
        SecretBox(cipher, nonce: nonce, mac: mac),
        secretKey: key,
      );

      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw const WrongPasswordException('Wrong master password.');
    } catch (_) {
      throw const FileCorruptedException(
        'Vault file is corrupted or invalid.',
      );
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) {
    return _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
  }

  /// Secure random bytes generator
  List<int> _generateBytes(int length) {
    return List<int>.generate(
      length,
      (_) => _secureRandom.nextInt(256),
    );
  }
}
