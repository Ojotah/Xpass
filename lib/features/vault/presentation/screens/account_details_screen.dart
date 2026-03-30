import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/account.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/vault_providers.dart';
import 'add_account_screen.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  const AccountDetailsScreen({
    super.key,
    required this.index,
    required this.account,
  });

  final int index;
  final Account account;

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  bool _showPassword = false;

  Future<void> _copyPassword() async {
    await ref.read(copyToClipboardUseCaseProvider).call(
          widget.account.password,
          autoClear: (ref.read(settingsControllerProvider).valueOrNull ??
                  AppSettings.defaults)
              .clipboardClearEnabled,
          clearAfter: Duration(
            seconds: (ref.read(settingsControllerProvider).valueOrNull ??
                    AppSettings.defaults)
                .clipboardClearDuration,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard.')),
    );
  }

  Future<void> _delete() async {
    final approved = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!approved) return;

    await ref
        .read(vaultControllerProvider.notifier)
        .deleteAccountAt(widget.index);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = widget.account;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AddAccountScreen(
                    index: widget.index,
                    initialAccount: widget.account,
                  ),
                ),
              );
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              a.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              a.username,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Safety',
              icon: Icons.shield_outlined,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risk score',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            '${a.riskScore} / 100',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (a.isCompromised) ...[
              const SizedBox(height: 12),
              Material(
                color: scheme.errorContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: scheme.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This password appears in known breach datasets. Change it soon.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onErrorContainer,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (a.note.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionHeader(
                title: 'Note',
                icon: Icons.notes_rounded,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    a.note,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Password',
              icon: Icons.key_rounded,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _showPassword ? a.password : List.filled(12, '•').join(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: _showPassword ? 0 : 2,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  label: Text(_showPassword ? 'Hide' : 'Reveal'),
                ),
                OutlinedButton.icon(
                  onPressed: _copyPassword,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: _delete,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
