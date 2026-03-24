import 'package:flutter/material.dart';

import '../../domain/entities/account.dart';

class AccountListTile extends StatelessWidget {
  const AccountListTile({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lock_outline),
        title: Text(account.title),
        subtitle: Text(account.username),
      ),
    );
  }
}
