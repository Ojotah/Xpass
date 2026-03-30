import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/entities/app_vault.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../vault/presentation/providers/vault_providers.dart';
import '../../../vault/presentation/screens/lock_screen.dart';

class StartupVaultSelectionScreen extends ConsumerWidget {
  const StartupVaultSelectionScreen({super.key, required this.vaults});

  final List<AppVault> vaults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Vault')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: vaults.length,
                itemBuilder: (context, index) {
                  final vault = vaults[index];
                  return Card(
                    child: ListTile(
                      title: Text(vault.name),
                      subtitle: vault.passwordHint.trim().isEmpty
                          ? null
                          : Text('Hint: ${vault.passwordHint}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .switchVault(vault.id);
                        if (!context.mounted) return;
                        Navigator.of(context)
                            .pushReplacementNamed(LockScreen.routeName);
                      },
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _importVault(context, ref),
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Import Vault'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importVault(BuildContext context, WidgetRef ref) async {
    final pick = await FilePicker.platform.pickFiles(type: FileType.any);
    final sourcePath = pick?.files.single.path;
    if (sourcePath == null) {
      return;
    }

    final vaultId = DateTime.now().millisecondsSinceEpoch.toString();
    final temporaryFileName = '$vaultId.dat';
    try {
      final metadata = await ref.read(importVaultUseCaseProvider).call(
            vaultId: vaultId,
            vaultFileName: temporaryFileName,
            sourcePath: sourcePath,
          );
      final targetFileName = '${metadata.name}.dat';
      final settings = ref.read(settingsControllerProvider).valueOrNull;
      final hasNameConflict =
          settings?.vaults.any((item) => item.fileName == targetFileName) ??
              false;
      final fileName = hasNameConflict ? temporaryFileName : targetFileName;
      if (fileName != temporaryFileName) {
        await ref.read(renameVaultUseCaseProvider).call(
              vaultId: vaultId,
              oldFileName: temporaryFileName,
              newFileName: fileName,
              metadata: metadata,
            );
      }
      await ref.read(settingsControllerProvider.notifier).upsertVault(
            AppVault(
              id: vaultId,
              name: metadata.name,
              passwordHint: metadata.hint,
              createdAt: metadata.createdAt,
              fileName: fileName,
            ),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vault imported.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Import failed.')));
    }
  }
}
