import 'package:flutter_test/flutter_test.dart';
import 'package:xpass/core/error/exceptions.dart';
import 'package:xpass/core/security/aes_encryption_service.dart';

void main() {
  group('AesEncryptionService', () {
    const plain = 'super-secret-value';
    const password = 'StrongMasterPassword!123';

    test('encrypts and decrypts payload', () async {
      final service = AesEncryptionService();

      final encrypted = await service.encrypt(plain, password);
      final decrypted = await service.decrypt(encrypted, password);

      expect(encrypted, isNot(plain));
      expect(decrypted, plain);
    });

    test('throws WrongPasswordException on invalid key', () async {
      final service = AesEncryptionService();
      final encrypted = await service.encrypt(plain, password);

      expect(
        () => service.decrypt(encrypted, 'bad-password'),
        throwsA(isA<WrongPasswordException>()),
      );
    });
  });
}
