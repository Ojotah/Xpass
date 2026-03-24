import 'package:flutter/material.dart';

import 'app_vault.dart';

class AppSettings {
  const AppSettings({
    required this.autoLockTimeout,
    required this.clipboardClearEnabled,
    required this.clipboardClearDuration,
    required this.biometricEnabled,
    required this.themeMode,
    required this.activeVaultId,
    required this.vaults,
  });

  final int autoLockTimeout;
  final bool clipboardClearEnabled;
  final int clipboardClearDuration;
  final bool biometricEnabled;
  final ThemeMode themeMode;
  final String activeVaultId;
  final List<AppVault> vaults;

  AppVault get activeVault => vaults.firstWhere(
        (vault) => vault.id == activeVaultId,
        orElse: () => vaults.first,
      );

  static const defaults = AppSettings(
    autoLockTimeout: 5,
    clipboardClearEnabled: true,
    clipboardClearDuration: 15,
    biometricEnabled: false,
    themeMode: ThemeMode.system,
    activeVaultId: 'default',
    vaults: [
      AppVault(id: 'default', name: 'My Vault', passwordHint: ''),
    ],
  );

  AppSettings copyWith({
    int? autoLockTimeout,
    bool? clipboardClearEnabled,
    int? clipboardClearDuration,
    bool? biometricEnabled,
    ThemeMode? themeMode,
    String? activeVaultId,
    List<AppVault>? vaults,
  }) {
    return AppSettings(
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      clipboardClearEnabled: clipboardClearEnabled ?? this.clipboardClearEnabled,
      clipboardClearDuration: clipboardClearDuration ?? this.clipboardClearDuration,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      themeMode: themeMode ?? this.themeMode,
      activeVaultId: activeVaultId ?? this.activeVaultId,
      vaults: vaults ?? this.vaults,
    );
  }
}
