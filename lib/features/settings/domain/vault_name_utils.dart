import 'entities/app_vault.dart';

/// Sanitizes vault display names for use as a single `.dat` filename segment.
abstract final class VaultNameUtils {
  static String sanitizeFileBasename(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'vault';
    final noIllegal = trimmed.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_');
    final collapsed = noIllegal.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.isEmpty ? 'vault' : collapsed;
  }

  static String fileNameForDisplayName(String displayName) =>
      '${sanitizeFileBasename(displayName)}.dat';

  /// True if another vault already uses this display name (case-insensitive)
  /// or the same resulting file name.
  static bool isNameTaken(
    List<AppVault> vaults,
    String displayName, {
    String? excludingVaultId,
  }) {
    final key = displayName.trim().toLowerCase();
    final file = fileNameForDisplayName(displayName);
    for (final v in vaults) {
      if (excludingVaultId != null && v.id == excludingVaultId) continue;
      if (v.name.toLowerCase() == key) return true;
      if (v.fileName == file) return true;
    }
    return false;
  }
}
