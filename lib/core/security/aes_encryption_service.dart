import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../error/exceptions.dart';
import 'encryption_service.dart';

class AesEncryptionService implements EncryptionService {
  const AesEncryptionService({
    AesGcm? algorithm,
    Pbkdf2? pbkdf2,
    Random? random,
  })  : _algorithm = algorithm ?? AesGcm.with256bits(),
        _pbkdf2 = pbkdf2 ??
            Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: 120000,
              bits: 256,
            ),
        _random = random ?? Cryptography.instance;

  final AesGcm _algorithm;
  final Pbkdf2 _pbkdf2;
  final Random _random;

  @override
  Future<String> encrypt(String plainText, String password) async {
    if (password.isEmpty) {
      throw const WrongPasswordException('Master password is required.');
    }

    final salt = _random.nextBytes(16);
    final nonce = _random.nextBytes(12);
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
      final decodedEnvelope = utf8.decode(base64Decode(cipherText));
      final payload = jsonDecode(decodedEnvelope) as Map<String, dynamic>;

      final salt = base64Decode(payload['salt'] as String);
      final nonce = base64Decode(payload['nonce'] as String);
      final encryptedBytes = base64Decode(payload['ct'] as String);
      final mac = Mac(base64Decode(payload['mac'] as String));

      final key = await _deriveKey(password, salt);
      final clearBytes = await _algorithm.decrypt(
        SecretBox(encryptedBytes, nonce: nonce, mac: mac),
        secretKey: key,
      );

      return utf8.decode(clearBytes);
    } on SecretBoxAuthenticationError {
      throw const WrongPasswordException('Wrong master password.');
    } on WrongPasswordException {
      rethrow;
    } catch (_) {
      throw const FileCorruptedException(
        'Vault file is corrupted or unsupported.',
      );
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) {
    return _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
  }
}
