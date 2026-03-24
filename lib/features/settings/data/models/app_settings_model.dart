import 'package:flutter/material.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_vault.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.autoLockTimeout,
    required super.clipboardClearEnabled,
    required super.clipboardClearDuration,
    required super.biometricEnabled,
    required super.themeMode,
    required super.activeVaultId,
    required super.vaults,
    super.lastBreachCheck,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      autoLockTimeout: settings.autoLockTimeout,
      clipboardClearEnabled: settings.clipboardClearEnabled,
      clipboardClearDuration: settings.clipboardClearDuration,
      biometricEnabled: settings.biometricEnabled,
      themeMode: settings.themeMode,
      activeVaultId: settings.activeVaultId,
      vaults: settings.vaults,
      lastBreachCheck: settings.lastBreachCheck,
    );
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    final vaults = (json['vaults'] as List<dynamic>? ?? const [])
        .map((item) => _vaultFromJson(item as Map<String, dynamic>))
        .toList();

    final fallbackVaults = vaults.isEmpty
        ? const [AppVault(id: 'default', name: 'My Vault', passwordHint: '')]
        : vaults;

    return AppSettingsModel(
      autoLockTimeout: (json['autoLockTimeout'] as num?)?.toInt() ?? 5,
      clipboardClearEnabled: json['clipboardClearEnabled'] as bool? ?? true,
      clipboardClearDuration: (json['clipboardClearDuration'] as num?)?.toInt() ?? 15,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      themeMode: _themeModeFromString(json['themeMode'] as String?),
      activeVaultId: json['activeVaultId'] as String? ?? fallbackVaults.first.id,
      vaults: fallbackVaults,
      lastBreachCheck: _dateTimeFromString(json['lastBreachCheck'] as String?),
    );
  }

  static AppVault _vaultFromJson(Map<String, dynamic> json) {
    return AppVault(
      id: json['id'] as String,
      name: json['name'] as String,
      passwordHint: json['passwordHint'] as String? ?? '',
    );
  }

  static ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  static DateTime? _dateTimeFromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Map<String, dynamic> toJson() {
    return {
      'autoLockTimeout': autoLockTimeout,
      'clipboardClearEnabled': clipboardClearEnabled,
      'clipboardClearDuration': clipboardClearDuration,
      'biometricEnabled': biometricEnabled,
      'themeMode': _themeModeToString(themeMode),
      'activeVaultId': activeVaultId,
      'vaults': vaults
          .map(
            (vault) => {
              'id': vault.id,
              'name': vault.name,
              'passwordHint': vault.passwordHint,
            },
          )
          .toList(),
      'lastBreachCheck': lastBreachCheck?.toUtc().toIso8601String(),
    };
  }
}
