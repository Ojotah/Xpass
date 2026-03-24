import '../../domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.autoLockTimeout,
    required super.clipboardClearEnabled,
    required super.clipboardClearDuration,
    required super.vaultName,
    required super.passwordHint,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      autoLockTimeout: settings.autoLockTimeout,
      clipboardClearEnabled: settings.clipboardClearEnabled,
      clipboardClearDuration: settings.clipboardClearDuration,
      vaultName: settings.vaultName,
      passwordHint: settings.passwordHint,
    );
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      autoLockTimeout: (json['autoLockTimeout'] as num?)?.toInt() ?? 5,
      clipboardClearEnabled: json['clipboardClearEnabled'] as bool? ?? true,
      clipboardClearDuration: (json['clipboardClearDuration'] as num?)?.toInt() ?? 15,
      vaultName: json['vaultName'] as String? ?? 'My Vault',
      passwordHint: json['passwordHint'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoLockTimeout': autoLockTimeout,
      'clipboardClearEnabled': clipboardClearEnabled,
      'clipboardClearDuration': clipboardClearDuration,
      'vaultName': vaultName,
      'passwordHint': passwordHint,
    };
  }
}
