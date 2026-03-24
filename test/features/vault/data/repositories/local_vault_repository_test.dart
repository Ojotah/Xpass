import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpass/core/security/aes_encryption_service.dart';
import 'package:xpass/features/vault/data/repositories/local_vault_repository.dart';
import 'package:xpass/features/vault/domain/entities/account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;
  late LocalVaultRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('xpass_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return tempDir.path;
    });

    repository = LocalVaultRepository(AesEncryptionService());
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saves and loads a vault', () async {
    const vaultId = 'test-vault';
    const password = 'MasterPassword!123';
    final accounts = [
      const Account(title: 'Email', username: 'user@example.com', password: 'SecretPassword1!'),
    ];

    await repository.initializeVault(vaultId: vaultId, masterPassword: password);
    await repository.saveVault(vaultId: vaultId, accounts: accounts, masterPassword: password);

    final loaded = await repository.unlockVault(vaultId: vaultId, masterPassword: password);

    expect(loaded, hasLength(1));
    expect(loaded.first.title, 'Email');
    expect(loaded.first.password, 'SecretPassword1!');
  });
}
