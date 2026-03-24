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

  @override
  Future<bool> vaultExists(String vaultId) async {
    final file = await _resolveVaultFile(vaultId);
    return file.exists();
  }

  @override
  Future<void> initializeVault({
    required String vaultId,
    required String masterPassword,
  }) async {
    final file = await _resolveVaultFile(vaultId);
    if (await file.exists()) {
      return;
    }

    await _writeEncryptedVault(file, const [], masterPassword);
  }

  @override
  Future<List<Account>> unlockVault({
    required String vaultId,
    required String masterPassword,
  }) async {
    final file = await _resolveVaultFile(vaultId);

    if (!await file.exists()) {
      throw const VaultException('Vault is not initialized.');
    }

    final encryptedPayload = await file.readAsString();
    if (encryptedPayload.trim().isEmpty) {
      throw const FileCorruptedException('Vault file is empty.');
    }

    final decrypted = await _encryptionService.decrypt(
      encryptedPayload,
      masterPassword,
    );

    return _deserializeAccounts(decrypted);
  }

  @override
  Future<void> saveVault({
    required String vaultId,
    required List<Account> accounts,
    required String masterPassword,
  }) async {
    final file = await _resolveVaultFile(vaultId);
    await _writeEncryptedVault(file, accounts, masterPassword);
  }

  @override
  Future<void> changeMasterPassword({
    required String vaultId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final file = await _resolveVaultFile(vaultId);
    if (!await file.exists()) {
      throw const VaultException('Vault is not initialized.');
    }

    final encryptedPayload = await file.readAsString();
    final decrypted = await _encryptionService.decrypt(encryptedPayload, currentPassword);
    final accounts = _deserializeAccounts(decrypted);

    try {
      await _writeEncryptedVault(file, accounts, newPassword);
    } finally {
      accounts.clear();
    }
  }

  @override
  Future<File> exportVault({required String vaultId, required String targetPath}) async {
    final vaultFile = await _resolveVaultFile(vaultId);
    if (!await vaultFile.exists()) {
      throw const VaultException('Vault does not exist.');
    }

    return vaultFile.copy(targetPath);
  }

  @override
  Future<void> importVault({required String vaultId, required String sourcePath}) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const VaultException('Selected import file does not exist.');
    }

    final content = await source.readAsString();
    if (content.trim().isEmpty) {
      throw const FileCorruptedException('Import file is empty.');
    }

    final target = await _resolveVaultFile(vaultId);
    await target.writeAsString(content, flush: true);
  }

  @override
  Future<void> deleteVault(String vaultId) async {
    final file = await _resolveVaultFile(vaultId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _resolveVaultFile(String vaultId) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final vaultDirectory = Directory('${documentsDirectory.path}/vaults');
    await vaultDirectory.create(recursive: true);
    return File('${vaultDirectory.path}/$vaultId.dat');
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
