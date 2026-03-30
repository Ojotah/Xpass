import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/entities/app_vault.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../vault/domain/entities/vault_metadata.dart';
import '../../../vault/presentation/providers/vault_providers.dart';
import '../../../vault/presentation/screens/lock_screen.dart';

class VaultSelectionScreen extends ConsumerWidget {
  const VaultSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).valueOrNull;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vaults')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final vault in settings.vaults)
            Card(
              child: ListTile(
                title: Text(vault.name),
                subtitle: Text(vault.id),
                leading: Icon(
                  settings.activeVaultId == vault.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                onTap: () async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .switchVault(vault.id);
                  await ref
                      .read(vaultControllerProvider.notifier)
                      .switchVault();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(
                        LockScreen.routeName, (route) => false);
                  }
                },
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _renameVault(context, ref, vault, settings.vaults),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: settings.vaults.length <= 1
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete vault?'),
                                  content: Text(
                                      'Delete "${vault.name}" permanently?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await ref.read(deleteVaultUseCaseProvider).call(
                                      vaultId: vault.id,
                                      vaultFileName: vault.fileName,
                                    );
                                await ref
                                    .read(settingsControllerProvider.notifier)
                                    .deleteVault(vault.id);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createVault(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Vault'),
      ),
    );
  }

  Future<void> _createVault(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final hintController = TextEditingController();
    final passController = TextEditingController();
    final created = await showDialog<AppVault>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create vault'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: hintController,
                decoration: const InputDecoration(labelText: 'Hint')),
            TextField(
                controller: passController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Master Password')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              final name = nameController.text.trim();
              Navigator.of(context).pop(
                AppVault(
                  id: id,
                  name: name,
                  passwordHint: hintController.text.trim(),
                  createdAt: DateTime.now().toUtc(),
                  fileName: '$name.dat',
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != null) {
      await ref.read(settingsControllerProvider.notifier).upsertVault(created);
      await ref
          .read(settingsControllerProvider.notifier)
          .switchVault(created.id);
      await ref
          .read(vaultControllerProvider.notifier)
          .initialize(passController.text);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    nameController.dispose();
    hintController.dispose();
    passController.dispose();
  }

  Future<void> _renameVault(
    BuildContext context,
    WidgetRef ref,
    AppVault vault,
    List<AppVault> allVaults,
  ) async {
    final nameController = TextEditingController(text: vault.name);
    final hintController = TextEditingController(text: vault.passwordHint);
    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename vault'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Vault Name')),
            TextField(
                controller: hintController,
                decoration: const InputDecoration(labelText: 'Hint')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context)
                .pop((nameController.text.trim(), hintController.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    hintController.dispose();
    if (result == null) return;

    final nextName = result.$1;
    final nextHint = result.$2;
    if (nextName.isEmpty) return;
    final nextFileName = '$nextName.dat';
    final duplicate = allVaults
        .any((item) => item.id != vault.id && item.fileName == nextFileName);
    if (duplicate) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Another vault already uses this name.')),
        );
      }
      return;
    }

    await ref.read(renameVaultUseCaseProvider).call(
          vaultId: vault.id,
          oldFileName: vault.fileName,
          newFileName: nextFileName,
          metadata: VaultMetadata(
            name: nextName,
            hint: nextHint,
            createdAt: vault.createdAt,
          ),
        );
    await ref.read(settingsControllerProvider.notifier).upsertVault(
          vault.copyWith(
            name: nextName,
            passwordHint: nextHint,
            fileName: nextFileName,
          ),
        );
  }
}
