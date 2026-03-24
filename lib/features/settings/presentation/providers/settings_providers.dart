import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/domain/usecases/update_theme.dart';
import '../../data/datasources/local_settings_datasource.dart';
import '../../data/repositories/local_settings_repository.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_vault.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';

final localSettingsDataSourceProvider = Provider<LocalSettingsDataSource>((ref) {
  return LocalSettingsDataSource();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepository(ref.watch(localSettingsDataSourceProvider));
});

final getSettingsUseCaseProvider = Provider<GetSettings>((ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
});

final updateSettingsUseCaseProvider = Provider<UpdateSettings>((ref) {
  return UpdateSettings(ref.watch(settingsRepositoryProvider));
});

final updateThemeUseCaseProvider = Provider<UpdateTheme>((ref) {
  return UpdateTheme(ref.watch(settingsRepositoryProvider));
});

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.read(getSettingsUseCaseProvider).call();
  }

  Future<void> saveSettings(AppSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateSettingsUseCaseProvider).call(settings);
      return settings;
    });
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    await ref.read(updateThemeUseCaseProvider).call(current: current, themeMode: themeMode);
    state = AsyncData(current.copyWith(themeMode: themeMode));
  }

  Future<void> switchVault(String vaultId) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    final next = current.copyWith(activeVaultId: vaultId);
    await ref.read(updateSettingsUseCaseProvider).call(next);
    state = AsyncData(next);
  }

  Future<void> upsertVault(AppVault vault) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    final vaults = [...current.vaults];
    final index = vaults.indexWhere((item) => item.id == vault.id);
    if (index >= 0) {
      vaults[index] = vault;
    } else {
      vaults.add(vault);
    }

    final next = current.copyWith(vaults: vaults);
    await ref.read(updateSettingsUseCaseProvider).call(next);
    state = AsyncData(next);
  }


  Future<void> updateLastBreachCheck(DateTime timestamp) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    final next = current.copyWith(lastBreachCheck: timestamp.toUtc());
    await ref.read(updateSettingsUseCaseProvider).call(next);
    state = AsyncData(next);
  }

  Future<void> deleteVault(String vaultId) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    if (current.vaults.length <= 1) {
      return;
    }

    final vaults = current.vaults.where((vault) => vault.id != vaultId).toList();
    final nextActive = current.activeVaultId == vaultId ? vaults.first.id : current.activeVaultId;
    final next = current.copyWith(vaults: vaults, activeVaultId: nextActive);
    await ref.read(updateSettingsUseCaseProvider).call(next);
    state = AsyncData(next);
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(SettingsController.new);
