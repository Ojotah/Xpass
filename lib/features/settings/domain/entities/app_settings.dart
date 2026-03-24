class AppSettings {
  const AppSettings({
    required this.autoLockTimeout,
    required this.clipboardClearEnabled,
    required this.clipboardClearDuration,
    required this.vaultName,
    required this.passwordHint,
  });

  final int autoLockTimeout;
  final bool clipboardClearEnabled;
  final int clipboardClearDuration;
  final String vaultName;
  final String passwordHint;

  static const defaults = AppSettings(
    autoLockTimeout: 5,
    clipboardClearEnabled: true,
    clipboardClearDuration: 15,
    vaultName: 'My Vault',
    passwordHint: '',
  );

  AppSettings copyWith({
    int? autoLockTimeout,
    bool? clipboardClearEnabled,
    int? clipboardClearDuration,
    String? vaultName,
    String? passwordHint,
  }) {
    return AppSettings(
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      clipboardClearEnabled: clipboardClearEnabled ?? this.clipboardClearEnabled,
      clipboardClearDuration: clipboardClearDuration ?? this.clipboardClearDuration,
      vaultName: vaultName ?? this.vaultName,
      passwordHint: passwordHint ?? this.passwordHint,
    );
  }
}
