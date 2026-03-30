import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/security/encryption_service.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/vault_metadata.dart';
import '../../domain/repositories/vault_repository.dart';
import '../models/account_model.dart';

class LocalVaultRepository implements VaultRepository {
  LocalVaultRepository(this._encryptionService);

  final EncryptionService _encryptionService;

  @override
  Future<bool> vaultExists(String vaultFileName) async {
    final file = await _resolveVaultFile(vaultFileName);
    return file.exists();
  }

  @override
  Future<void> initializeVault({
    required String vaultId,
    required String vaultFileName,
    required String masterPassword,
    required VaultMetadata metadata,
  }) async {
    final file = await _resolveVaultFile(vaultFileName);
    if (await file.exists()) {
      return;
    }

    await _writeEncryptedVault(
      file: file,
      accounts: const [],
      masterPassword: masterPassword,
      metadata: metadata,
    );
  }

  @override
  Future<List<Account>> unlockVault({
    required String vaultId,
    required String vaultFileName,
    required String masterPassword,
  }) async {
    try {
      final file = await _resolveVaultFileForRead(
          vaultFileName: vaultFileName, vaultId: vaultId);

      if (!await file.exists()) {
        throw const VaultException('Vault is not initialized.');
      }

      final encryptedPayload =
          (await _readVaultDocument(file)).encryptedPayload;
      if (encryptedPayload.trim().isEmpty) {
        throw const FileCorruptedException('Vault file is empty.');
      }

      final decrypted = await _encryptionService.decrypt(
        encryptedPayload,
        masterPassword,
      );

      return _deserializeAccounts(decrypted);
    } on FileSystemException catch (error, stackTrace) {
      AppLogger.error(
        'File read failure while unlocking vault.',
        error: error,
        stackTrace: stackTrace,
        scope: 'vault-repo',
      );
      throw const VaultException('Unable to load vault.');
    }
  }

  @override
  Future<void> saveVault({
    required String vaultId,
    required String vaultFileName,
    required List<Account> accounts,
    required String masterPassword,
  }) async {
    try {
      final file = await _resolveVaultFileForRead(
          vaultFileName: vaultFileName, vaultId: vaultId);
      final metadata = await _readMetadata(file,
          fallbackName: _baseNameWithoutExt(vaultFileName));
      await _writeEncryptedVault(
        file: file,
        accounts: accounts,
        masterPassword: masterPassword,
        metadata: metadata,
      );
    } on FileSystemException catch (error, stackTrace) {
      AppLogger.error(
        'File write failure while saving vault.',
        error: error,
        stackTrace: stackTrace,
        scope: 'vault-repo',
      );
      throw const VaultException('Unable to save vault.');
    }
  }

  @override
  Future<void> changeMasterPassword({
    required String vaultId,
    required String vaultFileName,
    required String currentPassword,
    required String newPassword,
  }) async {
    final file = await _resolveVaultFileForRead(
        vaultFileName: vaultFileName, vaultId: vaultId);
    if (!await file.exists()) {
      throw const VaultException('Vault is not initialized.');
    }

    final document = await _readVaultDocument(file);
    final encryptedPayload = document.encryptedPayload;
    final decrypted =
        await _encryptionService.decrypt(encryptedPayload, currentPassword);
    final accounts = _deserializeAccounts(decrypted);

    try {
      await _writeEncryptedVault(
        file: file,
        accounts: accounts,
        masterPassword: newPassword,
        metadata: document.metadata,
      );
    } finally {
      accounts.clear();
    }
  }

  @override
  Future<File> exportVault({
    required String vaultId,
    required String vaultFileName,
    required String targetPath,
  }) async {
    final vaultFile = await _resolveVaultFileForRead(
        vaultFileName: vaultFileName, vaultId: vaultId);
    if (!await vaultFile.exists()) {
      throw const VaultException('Vault does not exist.');
    }

    return vaultFile.copy(targetPath);
  }

  @override
  Future<VaultMetadata> peekMetadataFromImportPath(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const VaultException('Selected import file does not exist.');
    }
    final document = await _readVaultDocument(source);
    return document.metadata;
  }

  @override
  Future<VaultMetadata> importVault({
    required String vaultId,
    required String vaultFileName,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const VaultException('Selected import file does not exist.');
    }

    final content = await source.readAsString();
    if (content.trim().isEmpty) {
      throw const FileCorruptedException('Import file is empty.');
    }

    final target = await _resolveVaultFile(vaultFileName);
    await target.writeAsString(content, flush: true);
    final sourceFileName = source.uri.pathSegments.isEmpty
        ? 'Imported Vault'
        : source.uri.pathSegments.last;
    final metadata = await _readMetadata(
      target,
      fallbackName: _baseNameWithoutExt(sourceFileName),
    );
    final document = await _readVaultDocument(target);
    await _writeVaultDocument(
      file: target,
      encryptedPayload: document.encryptedPayload,
      metadata: metadata,
    );
    return metadata;
  }

  @override
  Future<void> deleteVault(
      {required String vaultId, required String vaultFileName}) async {
    final file = await _resolveVaultFileForRead(
        vaultFileName: vaultFileName, vaultId: vaultId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> renameVault({
    required String vaultId,
    required String oldFileName,
    required String newFileName,
    required VaultMetadata metadata,
  }) async {
    final oldFile = await _resolveVaultFileForRead(
        vaultFileName: oldFileName, vaultId: vaultId);
    if (!await oldFile.exists()) {
      throw const VaultException('Vault does not exist.');
    }

    final newFile = await _resolveVaultFile(newFileName);
    if (oldFile.path != newFile.path && await newFile.exists()) {
      throw const VaultException('A vault with this name already exists.');
    }

    final renamed = oldFile.path == newFile.path
        ? oldFile
        : await oldFile.rename(newFile.path);
    final document = await _readVaultDocument(renamed);
    await _writeVaultDocument(
      file: renamed,
      encryptedPayload: document.encryptedPayload,
      metadata: metadata,
    );
  }

  @override
  Future<void> updateVaultMetadata({
    required String vaultId,
    required String vaultFileName,
    required VaultMetadata metadata,
  }) async {
    final file = await _resolveVaultFileForRead(
        vaultFileName: vaultFileName, vaultId: vaultId);
    final document = await _readVaultDocument(file);
    await _writeVaultDocument(
      file: file,
      encryptedPayload: document.encryptedPayload,
      metadata: metadata,
    );
  }

  Future<File> _resolveVaultFile(String vaultFileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final vaultDirectory = Directory('${documentsDirectory.path}/vaults');
    await vaultDirectory.create(recursive: true);
    return File('${vaultDirectory.path}/$vaultFileName');
  }

  Future<File> _resolveVaultFileForRead({
    required String vaultFileName,
    required String vaultId,
  }) async {
    final preferred = await _resolveVaultFile(vaultFileName);
    if (await preferred.exists()) {
      return preferred;
    }

    final legacy = await _resolveVaultFile('$vaultId.dat');
    if (await legacy.exists()) {
      return legacy;
    }

    return preferred;
  }

  Future<void> _writeEncryptedVault({
    required File file,
    required List<Account> accounts,
    required String masterPassword,
    required VaultMetadata metadata,
  }) async {
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

    await _writeVaultDocument(
      file: file,
      encryptedPayload: encrypted,
      metadata: metadata,
    );
  }

  Future<void> _writeVaultDocument({
    required File file,
    required String encryptedPayload,
    required VaultMetadata metadata,
  }) async {
    final document = {
      'metadata': metadata.toJson(),
      'data': {
        'encryptedPayload': encryptedPayload,
      },
    };

    await file.writeAsString(jsonEncode(document), flush: true);
  }

  Future<_VaultDocument> _readVaultDocument(File file) async {
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      throw const FileCorruptedException('Vault file is empty.');
    }

    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        final metadataJson = decoded['metadata'];
        final dataJson = decoded['data'];
        final encryptedPayload = dataJson is Map<String, dynamic>
            ? dataJson['encryptedPayload'] as String?
            : null;
        if (metadataJson is Map<String, dynamic> && encryptedPayload != null) {
          return _VaultDocument(
            encryptedPayload: encryptedPayload,
            metadata: VaultMetadata.fromJson(metadataJson),
          );
        }
      }
    } catch (_) {
      // Legacy format support below.
    }

    return _VaultDocument(
      encryptedPayload: content,
      metadata: await _readMetadata(file,
          fallbackName: _baseNameWithoutExt(file.path)),
    );
  }

  Future<VaultMetadata> _readMetadata(File file,
      {required String fallbackName}) async {
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic> &&
          decoded['metadata'] is Map<String, dynamic>) {
        return VaultMetadata.fromJson(
            decoded['metadata'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Legacy format fallback.
    }

    final stat = await file.stat();
    return VaultMetadata(
      name: fallbackName,
      hint: '',
      createdAt: stat.changed.toUtc(),
    );
  }

  String _baseNameWithoutExt(String pathOrFile) {
    final value = pathOrFile.split(Platform.pathSeparator).last;
    return value.endsWith('.dat')
        ? value.substring(0, value.length - 4)
        : value;
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

class _VaultDocument {
  const _VaultDocument({
    required this.encryptedPayload,
    required this.metadata,
  });

  final String encryptedPayload;
  final VaultMetadata metadata;
}
