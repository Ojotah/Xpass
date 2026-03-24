import 'package:flutter/material.dart';

import '../../domain/entities/account.dart';

class AccountListTile extends StatelessWidget {
  const AccountListTile({
    super.key,
    required this.account,
    required this.onTap,
  });

  final Account account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.lock_outline),
        title: Text(account.title),
        subtitle: Text(account.username),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
