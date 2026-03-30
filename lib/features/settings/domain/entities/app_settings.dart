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
    this.lastBreachCheck,
  });

  final int autoLockTimeout;
  final bool clipboardClearEnabled;
  final int clipboardClearDuration;
  final bool biometricEnabled;
  final ThemeMode themeMode;
  final String activeVaultId;
  final List<AppVault> vaults;
  final DateTime? lastBreachCheck;

  /// Selected vault, or first vault if the id is missing, or null if there are none.
  AppVault? get activeVaultOrNull {
    if (vaults.isEmpty) return null;
    if (activeVaultId.isEmpty) return vaults.first;
    for (final v in vaults) {
      if (v.id == activeVaultId) return v;
    }
    return vaults.first;
  }

  AppVault get activeVault {
    final v = activeVaultOrNull;
    if (v == null) {
      throw StateError('No vault configured');
    }
    return v;
  }

  static const defaults = AppSettings(
    autoLockTimeout: 5,
    clipboardClearEnabled: true,
    clipboardClearDuration: 15,
    biometricEnabled: false,
    themeMode: ThemeMode.system,
    activeVaultId: '',
    vaults: [],
    lastBreachCheck: null,
  );

  AppSettings copyWith({
    int? autoLockTimeout,
    bool? clipboardClearEnabled,
    int? clipboardClearDuration,
    bool? biometricEnabled,
    ThemeMode? themeMode,
    String? activeVaultId,
    List<AppVault>? vaults,
    DateTime? lastBreachCheck,
    bool clearLastBreachCheck = false,
  }) {
    return AppSettings(
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      clipboardClearEnabled:
          clipboardClearEnabled ?? this.clipboardClearEnabled,
      clipboardClearDuration:
          clipboardClearDuration ?? this.clipboardClearDuration,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      themeMode: themeMode ?? this.themeMode,
      activeVaultId: activeVaultId ?? this.activeVaultId,
      vaults: vaults ?? this.vaults,
      lastBreachCheck: clearLastBreachCheck
          ? null
          : (lastBreachCheck ?? this.lastBreachCheck),
    );
  }
}
