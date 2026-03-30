import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/entities/app_vault.dart';
import '../../../settings/domain/vault_name_utils.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../vault/domain/entities/vault_metadata.dart';
import '../../../vault/presentation/providers/vault_providers.dart';
import '../../../vault/presentation/screens/lock_screen.dart';

class StartupVaultSelectionScreen extends ConsumerWidget {
  const StartupVaultSelectionScreen({super.key, required this.vaults});

  final List<AppVault> vaults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).valueOrNull;
    final activeId = settings?.activeVaultId;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open vault'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              'Choose a vault to unlock. Your data stays encrypted on this device.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: vaults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final vault = vaults[index];
                final isActive = vault.id == activeId;

                return _VaultPickCard(
                  vault: vault,
                  selected: isActive,
                  onTap: () async {
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .switchVault(vault.id);
                    if (!context.mounted) return;
                    Navigator.of(context)
                        .pushReplacementNamed(LockScreen.routeName);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.tonalIcon(
              onPressed: () => _importVault(context, ref),
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Import vault file'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importVault(BuildContext context, WidgetRef ref) async {
    final pick = await FilePicker.platform.pickFiles(type: FileType.any);
    final sourcePath = pick?.files.single.path;
    if (sourcePath == null) {
      return;
    }

    late final VaultMetadata peeked;
    try {
      peeked =
          await ref.read(peekVaultMetadataUseCaseProvider).call(sourcePath);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read vault file.')),
      );
      return;
    }

    final existing =
        ref.read(settingsControllerProvider).valueOrNull?.vaults ?? [];
    if (VaultNameUtils.isNameTaken(existing, peeked.name)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This vault is already imported.'),
        ),
      );
      return;
    }

    final vaultId = DateTime.now().millisecondsSinceEpoch.toString();
    final targetFileName = VaultNameUtils.fileNameForDisplayName(peeked.name);

    try {
      final metadata = await ref.read(importVaultUseCaseProvider).call(
            vaultId: vaultId,
            vaultFileName: targetFileName,
            sourcePath: sourcePath,
          );
      await ref.read(settingsControllerProvider.notifier).upsertVault(
            AppVault(
              id: vaultId,
              name: metadata.name,
              passwordHint: metadata.hint,
              createdAt: metadata.createdAt,
              fileName: targetFileName,
            ),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault imported.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed.')),
      );
    }
  }
}

class _VaultPickCard extends StatelessWidget {
  const _VaultPickCard({
    required this.vault,
    required this.selected,
    required this.onTap,
  });

  final AppVault vault;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hint = vault.passwordHint.trim();

    return Material(
      elevation: selected ? 2 : 0,
      shadowColor: scheme.shadow,
      surfaceTintColor: scheme.surfaceTint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 2 : 1,
            ),
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      selected ? scheme.primary : scheme.surfaceContainerHigh,
                  foregroundColor:
                      selected ? scheme.onPrimary : scheme.onSurface,
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.folder_outlined,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vault.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      if (hint.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Hint available on unlock',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
