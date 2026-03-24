import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/aes_encryption_service.dart';
import '../../../../core/security/breach_checker.dart';
import '../../../../core/security/encryption_service.dart';
import '../../../../core/utils/clipboard_manager.dart';
import '../../../../core/utils/password_generator.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/repositories/local_vault_repository.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_category.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../domain/usecases/change_master_password.dart';
import '../../domain/usecases/check_password_breach.dart';
import '../../domain/usecases/check_vault_exists.dart';
import '../../domain/usecases/copy_to_clipboard.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/delete_vault.dart';
import '../../domain/usecases/detect_account_category.dart';
import '../../domain/usecases/export_vault.dart';
import '../../domain/usecases/generate_password.dart';
import '../../domain/usecases/get_accounts_by_category.dart';
import '../../domain/usecases/get_category_counts.dart';
import '../../domain/usecases/import_vault.dart';
import '../../domain/usecases/initialize_vault.dart';
import '../../domain/usecases/save_vault.dart';
import '../../domain/usecases/search_accounts.dart';
import '../../domain/usecases/unlock_vault.dart';
import '../../domain/usecases/update_account.dart';
import '../../domain/usecases/check_all_passwords_breach.dart';

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return AesEncryptionService();
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return LocalVaultRepository(ref.watch(encryptionServiceProvider));
});

final checkVaultExistsUseCaseProvider = Provider<CheckVaultExists>((ref) {
  return CheckVaultExists(ref.watch(vaultRepositoryProvider));
});

final initializeVaultUseCaseProvider = Provider<InitializeVault>((ref) {
  return InitializeVault(ref.watch(vaultRepositoryProvider));
});

final unlockVaultUseCaseProvider = Provider<UnlockVault>((ref) {
  return UnlockVault(ref.watch(vaultRepositoryProvider));
});

final saveVaultUseCaseProvider = Provider<SaveVault>((ref) {
  return SaveVault(ref.watch(vaultRepositoryProvider));
});

final changeMasterPasswordUseCaseProvider = Provider<ChangeMasterPassword>((ref) {
  return ChangeMasterPassword(ref.watch(vaultRepositoryProvider));
});

final exportVaultUseCaseProvider = Provider<ExportVault>((ref) {
  return ExportVault(ref.watch(vaultRepositoryProvider));
});

final importVaultUseCaseProvider = Provider<ImportVault>((ref) {
  return ImportVault(ref.watch(vaultRepositoryProvider));
});

final deleteVaultUseCaseProvider = Provider<DeleteVault>((ref) {
  return DeleteVault(ref.watch(vaultRepositoryProvider));
});

final passwordGeneratorProvider = Provider<PasswordGenerator>((ref) {
  return const PasswordGenerator();
});

final generatePasswordUseCaseProvider = Provider<GeneratePassword>((ref) {
  return GeneratePassword(ref.watch(passwordGeneratorProvider));
});

final clipboardManagerProvider = Provider<ClipboardManager>((ref) {
  final manager = ClipboardManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final copyToClipboardUseCaseProvider = Provider<CopyToClipboard>((ref) {
  return CopyToClipboard(ref.watch(clipboardManagerProvider));
});

final breachCheckerProvider = Provider<BreachChecker>((ref) {
  return KAnonymityBreachChecker();
});

final checkPasswordBreachUseCaseProvider = Provider<CheckPasswordBreach>((ref) {
  return CheckPasswordBreach(ref.watch(breachCheckerProvider));
});

final checkAllPasswordsBreachUseCaseProvider = Provider<CheckAllPasswordsBreach>((ref) {
  return CheckAllPasswordsBreach(ref.watch(checkPasswordBreachUseCaseProvider));
});

final searchAccountsUseCaseProvider = Provider<SearchAccounts>((ref) {
  return const SearchAccounts();
});

final deleteAccountUseCaseProvider = Provider<DeleteAccount>((ref) {
  return const DeleteAccount();
});

final updateAccountUseCaseProvider = Provider<UpdateAccount>((ref) {
  return const UpdateAccount();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final detectAccountCategoryUseCaseProvider = Provider<DetectAccountCategory>((ref) {
  return const DetectAccountCategory();
});

final getAccountsByCategoryUseCaseProvider = Provider<GetAccountsByCategory>((ref) {
  return GetAccountsByCategory(ref.watch(detectAccountCategoryUseCaseProvider));
});

final getCategoryCountsUseCaseProvider = Provider<GetCategoryCounts>((ref) {
  return GetCategoryCounts(ref.watch(detectAccountCategoryUseCaseProvider));
});

final selectedCategoryProvider = StateProvider<AccountCategory>((ref) => AccountCategory.all);

final filteredAccountsProvider = Provider<List<Account>>((ref) {
  final accounts = ref.watch(
    vaultControllerProvider.select((value) => value.valueOrNull?.accounts ?? const []),
  );
  final query = ref.watch(searchQueryProvider);

  return ref.watch(searchAccountsUseCaseProvider).call(accounts, query);
});

final categoryCountsProvider = Provider<Map<AccountCategory, int>>((ref) {
  final accounts = ref.watch(
    vaultControllerProvider.select((value) => value.valueOrNull?.accounts ?? const []),
  );
  return ref.watch(getCategoryCountsUseCaseProvider).call(accounts);
});

class VaultState {
  const VaultState({
    required this.isUnlocked,
    required this.accounts,
    this.errorMessage,
  });

  final bool isUnlocked;
  final List<Account> accounts;
  final String? errorMessage;

  VaultState copyWith({
    bool? isUnlocked,
    List<Account>? accounts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VaultState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      accounts: accounts ?? this.accounts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const locked = VaultState(isUnlocked: false, accounts: []);
}

class VaultController extends AsyncNotifier<VaultState> {
  String? _sessionPassword;
  Timer? _autoLockTimer;
  bool _isBreachCheckRunning = false;

  String get _activeVaultId {
    final settings = ref.read(settingsControllerProvider).valueOrNull ?? AppSettings.defaults;
    return settings.activeVaultId;
  }

  @override
  Future<VaultState> build() async {
    ref.onDispose(() => _autoLockTimer?.cancel());
    return VaultState.locked;
  }

  Future<void> unlock(String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final accounts =
          await ref.read(unlockVaultUseCaseProvider).call(vaultId: _activeVaultId, masterPassword: password);

      _sessionPassword = password;
      _startInactivityTimer();
      unawaited(_runBreachScanIfNeeded(force: false));

      return VaultState(
        isUnlocked: true,
        accounts: accounts,
      );
    });
  }

  Future<void> initialize(String password) async {
    await ref
        .read(initializeVaultUseCaseProvider)
        .call(vaultId: _activeVaultId, masterPassword: password);
    _sessionPassword = password;
    state = const AsyncData(VaultState(isUnlocked: true, accounts: []));
    _startInactivityTimer();
  }

  Future<void> addAccount(Account account) async {
    final current = state.valueOrNull;
    if (current == null || !current.isUnlocked || _sessionPassword == null) {
      return;
    }

    final compromised = await _safeCheckCompromised(account.password);
    final nextAccounts = [...current.accounts, account.copyWith(isCompromised: compromised)];
    await _saveAndUpdateState(current, nextAccounts);
  }

  Future<void> updateAccountAt(int index, Account updated) async {
    final current = state.valueOrNull;
    if (current == null || !current.isUnlocked || _sessionPassword == null) {
      return;
    }

    final compromised = await _safeCheckCompromised(updated.password);
    final nextAccounts = ref
        .read(updateAccountUseCaseProvider)
        .call(current.accounts, index, updated.copyWith(isCompromised: compromised));
    await _saveAndUpdateState(current, nextAccounts);
  }

  Future<void> deleteAccountAt(int index) async {
    final current = state.valueOrNull;
    if (current == null || !current.isUnlocked || _sessionPassword == null) {
      return;
    }

    final nextAccounts = ref.read(deleteAccountUseCaseProvider).call(current.accounts, index);
    await _saveAndUpdateState(current, nextAccounts);
  }

  Future<void> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ref.read(changeMasterPasswordUseCaseProvider).call(
          vaultId: _activeVaultId,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    _sessionPassword = newPassword;
    _startInactivityTimer();
  }

  Future<int> runBreachScan({bool force = true}) async {
    return _runBreachScanIfNeeded(force: force);
  }

  Future<void> switchVault() async {
    _sessionPassword = null;
    state = const AsyncData(VaultState.locked);
  }

  void registerInteraction() {
    final current = state.valueOrNull;
    if (current?.isUnlocked ?? false) {
      _startInactivityTimer();
    }
  }

  void lock() {
    _autoLockTimer?.cancel();
    _sessionPassword = null;
    state = const AsyncData(VaultState.locked);
  }

  Future<void> _saveAndUpdateState(
    VaultState current,
    List<Account> nextAccounts,
  ) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(saveVaultUseCaseProvider).call(
            vaultId: _activeVaultId,
            accounts: nextAccounts,
            masterPassword: _sessionPassword!,
          );
      _startInactivityTimer();
      return current.copyWith(accounts: nextAccounts, clearError: true);
    });
  }

  void _startInactivityTimer() {
    _autoLockTimer?.cancel();
    final settings = ref.read(settingsControllerProvider).valueOrNull ?? AppSettings.defaults;
    final minutes = settings.autoLockTimeout;
    if (minutes <= 0) {
      return;
    }

    _autoLockTimer = Timer(Duration(minutes: minutes), lock);
  }

  Future<int> _runBreachScanIfNeeded({required bool force}) async {
    if (_isBreachCheckRunning) {
      return 0;
    }

    final settings = ref.read(settingsControllerProvider).valueOrNull ?? AppSettings.defaults;
    final lastCheck = settings.lastBreachCheck;
    final now = DateTime.now().toUtc();
    if (!force && lastCheck != null && now.difference(lastCheck).inDays < 3) {
      return 0;
    }

    _isBreachCheckRunning = true;
    try {
      final current = state.valueOrNull;
      if (current == null || !current.isUnlocked || _sessionPassword == null) {
        return 0;
      }

      final updatedAccounts =
          await ref.read(checkAllPasswordsBreachUseCaseProvider).call(current.accounts);

      await ref.read(saveVaultUseCaseProvider).call(
            vaultId: _activeVaultId,
            accounts: updatedAccounts,
            masterPassword: _sessionPassword!,
          );

      final compromisedCount =
          updatedAccounts.where((account) => account.isCompromised).length;
      state = AsyncData(current.copyWith(accounts: updatedAccounts, clearError: true));
      await ref.read(settingsControllerProvider.notifier).updateLastBreachCheck(now);
      return compromisedCount;
    } catch (_) {
      return -1;
    } finally {
      _isBreachCheckRunning = false;
    }
  }

  Future<bool> _safeCheckCompromised(String password) async {
    try {
      return await ref.read(checkPasswordBreachUseCaseProvider).call(password);
    } catch (_) {
      return false;
    }
  }
}

final vaultControllerProvider =
    AsyncNotifierProvider<VaultController, VaultState>(VaultController.new);
