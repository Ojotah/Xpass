import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/security/encryption_service.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/vault_repository.dart';
import '../models/account_model.dart';

class LocalVaultRepository implements VaultRepository {
  LocalVaultRepository(this._encryptionService);

  final EncryptionService _encryptionService;

  static const _vaultFileName = 'vault.dat';

  @override
  Future<List<Account>> unlockVault(String masterPassword) async {
    final file = await _resolveVaultFile();

    if (!await file.exists()) {
      await _writeEncryptedVault(file, const [], masterPassword);
      return const [];
    }

    final encryptedPayload = await file.readAsString();
    if (encryptedPayload.trim().isEmpty) {
      await _writeEncryptedVault(file, const [], masterPassword);
      return const [];
    }

    final decrypted = await _encryptionService.decrypt(
      encryptedPayload,
      masterPassword,
    );

    return _deserializeAccounts(decrypted);
  }

  @override
  Future<void> saveVault(List<Account> accounts, String masterPassword) async {
    final file = await _resolveVaultFile();
    await _writeEncryptedVault(file, accounts, masterPassword);
  }

  Future<File> _resolveVaultFile() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    await documentsDirectory.create(recursive: true);
    return File('${documentsDirectory.path}/$_vaultFileName');
  }

  Future<void> _writeEncryptedVault(
    File file,
    List<Account> accounts,
    String masterPassword,
  ) async {
    final vaultJson = {
      'version': 1,
      'accounts': accounts
          .map((account) => AccountModel.fromEntity(account).toJson())
          .toList(),
    };

    // Decrypted account data is only assembled in-memory and immediately
    // encrypted before writing to disk.
    final encrypted = await _encryptionService.encrypt(
      jsonEncode(vaultJson),
      masterPassword,
    );

    await file.writeAsString(encrypted, flush: true);
  }

  List<Account> _deserializeAccounts(String decryptedJson) {
    try {
      final payload = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final accounts = (payload['accounts'] as List<dynamic>? ?? const [])
          .map((json) => AccountModel.fromJson(json as Map<String, dynamic>))
          .cast<Account>()
          .toList();

      return accounts;
    } catch (_) {
      throw const FileCorruptedException('Vault data cannot be parsed.');
    }
  }
}
