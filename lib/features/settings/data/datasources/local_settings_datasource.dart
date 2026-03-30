import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_settings.dart';
import '../models/app_settings_model.dart';

class LocalSettingsDataSource {
  static const _settingsFileName = 'settings.json';

  Future<File> _resolveSettingsFile() async {
    final supportDirectory = await getApplicationSupportDirectory();
    await supportDirectory.create(recursive: true);
    return File('${supportDirectory.path}/$_settingsFileName');
  }

  Future<AppSettingsModel> readSettings() async {
    final file = await _resolveSettingsFile();
    if (!await file.exists()) {
      return AppSettingsModel.fromEntity(AppSettings.defaults);
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return AppSettingsModel.fromEntity(AppSettings.defaults);
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettingsModel.fromJson(decoded);
    } catch (_) {
      throw const FileCorruptedException('Settings file cannot be parsed.');
    }
  }

  Future<void> writeSettings(AppSettingsModel settings) async {
    final file = await _resolveSettingsFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      flush: true,
    );
  }
}
