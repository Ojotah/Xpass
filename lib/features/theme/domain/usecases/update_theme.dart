import 'package:flutter/material.dart';

import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/repositories/settings_repository.dart';

class UpdateTheme {
  const UpdateTheme(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  Future<void> call({
    required AppSettings current,
    required ThemeMode themeMode,
  }) {
    return _settingsRepository
        .updateSettings(current.copyWith(themeMode: themeMode));
  }
}
