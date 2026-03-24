import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/account_model.dart';

class LocalVaultDataSource {
  static const _vaultFileName = 'vault.json';

  Future<File> _resolveVaultFile() async {
    final supportDirectory = await getApplicationSupportDirectory();
    await supportDirectory.create(recursive: true);
    return File('${supportDirectory.path}/$_vaultFileName');
  }

  Future<List<AccountModel>> readAccounts() async {
    final file = await _resolveVaultFile();
    if (!await file.exists()) {
      return [
        const AccountModel(
          title: 'Email',
          username: 'user@example.com',
          password: 'demo_password',
        ),
        const AccountModel(
          title: 'GitHub',
          username: 'octocat',
          password: 'demo_password_2',
        ),
      ];
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return const [];
    }

    final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> rows = decoded['accounts'] as List<dynamic>? ?? const [];
    return rows
        .map((row) => AccountModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeAccounts(List<AccountModel> accounts) async {
    final file = await _resolveVaultFile();

    // Keeping metadata intentionally simple now so encrypted payload can be
    // introduced later without changing the calling API.
    final payload = {
      'version': 1,
      'encryption': 'none',
      'accounts': accounts.map((account) => account.toJson()).toList(),
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
  }
}
