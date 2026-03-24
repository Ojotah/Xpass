import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../settings/domain/usecases/get_settings.dart';

class SwitchVault {
  const SwitchVault(this._settingsRepository, this._getSettings);

  final SettingsRepository _settingsRepository;
  final GetSettings _getSettings;

  Future<void> call(String vaultId) async {
    final settings = await _getSettings.call();
    await _settingsRepository.updateSettings(settings.copyWith(activeVaultId: vaultId));
  }
}
