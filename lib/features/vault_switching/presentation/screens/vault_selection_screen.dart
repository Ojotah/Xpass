import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/entities/app_vault.dart';
import '../../../settings/domain/vault_name_utils.dart';
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaults'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: settings.vaults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final vault = settings.vaults[index];
          final isActive = settings.activeVaultId == vault.id;

          return Material(
            elevation: isActive ? 2 : 0,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .switchVault(vault.id);
                await ref.read(vaultControllerProvider.notifier).switchVault();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    LockScreen.routeName,
                    (route) => false,
                  );
                }
              },
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.55),
                    width: isActive ? 2 : 1,
                  ),
                  color: isActive
                      ? scheme.primaryContainer.withValues(alpha: 0.4)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isActive
                            ? scheme.primary
                            : scheme.surfaceContainerHigh,
                        foregroundColor:
                            isActive ? scheme.onPrimary : scheme.onSurface,
                        child: Icon(
                          isActive
                              ? Icons.check_circle_outline
                              : Icons.folder_outlined,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    vault.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                if (isActive)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Chip(
                                      label: const Text('Active'),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      labelStyle: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                      side: BorderSide.none,
                                      backgroundColor: scheme.primaryContainer,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vault.fileName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Rename',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _renameVault(context, ref, vault, settings.vaults),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: settings.vaults.length <= 1
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete vault?'),
                                    content: Text(
                                      'Delete "${vault.name}" and its file? This cannot be undone.',
                                    ),
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
                                  await ref
                                      .read(deleteVaultUseCaseProvider)
                                      .call(
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
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createVault(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New vault'),
      ),
    );
  }

  Future<void> _createVault(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final hintController = TextEditingController();
    final passController = TextEditingController();
    final dialogResult =
        await showDialog<({String name, String hint, String password})?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create vault'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Vault name',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hintController,
                decoration: const InputDecoration(
                  labelText: 'Password hint (optional)',
                  prefixIcon: Icon(Icons.lightbulb_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Master password',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(context).pop(
                (
                  name: name,
                  hint: hintController.text.trim(),
                  password: passController.text,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    nameController.dispose();
    hintController.dispose();
    passController.dispose();

    if (dialogResult == null) return;

    final vaults =
        ref.read(settingsControllerProvider).valueOrNull?.vaults ?? [];
    if (VaultNameUtils.isNameTaken(vaults, dialogResult.name)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A vault with this name already exists.'),
          ),
        );
      }
      return;
    }

    final vaultId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = VaultNameUtils.fileNameForDisplayName(dialogResult.name);
    final created = AppVault(
      id: vaultId,
      name: dialogResult.name,
      passwordHint: dialogResult.hint,
      createdAt: DateTime.now().toUtc(),
      fileName: fileName,
    );

    await ref.read(settingsControllerProvider.notifier).upsertVault(created);
    await ref.read(settingsControllerProvider.notifier).switchVault(created.id);
    await ref
        .read(vaultControllerProvider.notifier)
        .initialize(dialogResult.password);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
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
              decoration: const InputDecoration(labelText: 'Vault name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hintController,
              decoration: const InputDecoration(
                labelText: 'Password hint',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              (nameController.text.trim(), hintController.text.trim()),
            ),
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
    final nextFileName = VaultNameUtils.fileNameForDisplayName(nextName);
    if (VaultNameUtils.isNameTaken(
      allVaults,
      nextName,
      excludingVaultId: vault.id,
    )) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Another vault already uses this name.'),
          ),
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
