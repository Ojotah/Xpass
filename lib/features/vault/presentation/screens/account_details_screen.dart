import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account.dart';
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
  ConsumerState<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  bool _showPassword = false;

  Future<void> _copyPassword() async {
    await ref.read(copyToClipboardUseCaseProvider).call(
          widget.account.password,
          autoClear: ref.read(autoClearClipboardProvider),
          clearAfter: const Duration(seconds: 15),
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
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;

    if (!approved) return;

    await ref.read(vaultControllerProvider.notifier).deleteAccountAt(widget.index);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.account.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text('Username: ${widget.account.username}'),
                const SizedBox(height: 12),
                Text(
                  'Password: ${_showPassword ? widget.account.password : '••••••••••'}',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      label: Text(_showPassword ? 'Hide' : 'Show'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _copyPassword,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy password'),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AddAccountScreen(
                              index: widget.index,
                              initialAccount: widget.account,
                            ),
                          ),
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
