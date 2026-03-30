import 'package:flutter/material.dart';

import '../../domain/entities/account.dart';

/// Material 3 card for the password grid: title → email → note hierarchy.
class AccountPasswordCard extends StatelessWidget {
  const AccountPasswordCard({
    super.key,
    required this.account,
    required this.riskColor,
    required this.onTap,
  });

  final Account account;
  final Color riskColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final note = account.note.trim();
    final hasNote = note.isNotEmpty;

    return Material(
      elevation: 1,
      shadowColor: scheme.shadow,
      surfaceTintColor: scheme.surfaceTint,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        account.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.shield_outlined, size: 20, color: riskColor),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: account.riskScore / 100,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                  color: riskColor,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 12),
                Text(
                  account.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      hasNote ? note : '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasNote
                            ? scheme.onSurfaceVariant
                            : scheme.onSurfaceVariant.withValues(alpha: 0.45),
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (account.isCompromised)
                      _RiskChip(
                        label: 'Leaked',
                        color: scheme.error,
                      ),
                    if (account.isWeak)
                      _RiskChip(
                        label: 'Weak',
                        color: Colors.orange.shade700,
                      ),
                    if (account.isReused)
                      _RiskChip(
                        label: 'Reused',
                        color: Colors.amber.shade800,
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

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
