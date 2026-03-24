import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local_settings_datasource.dart';
import '../models/app_settings_model.dart';

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository(this._dataSource);

  final LocalSettingsDataSource _dataSource;

  @override
  Future<AppSettings> getSettings() async {
    final settings = await _dataSource.readSettings();
    return settings;
  }

  @override
  Future<void> updateSettings(AppSettings settings) {
    return _dataSource.writeSettings(AppSettingsModel.fromEntity(settings));
  }
}
