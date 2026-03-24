import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/aes_encryption_service.dart';
import '../../../../core/security/encryption_service.dart';
import '../../data/repositories/local_vault_repository.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../domain/usecases/save_vault.dart';
import '../../domain/usecases/unlock_vault.dart';

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return AesEncryptionService();
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return LocalVaultRepository(ref.watch(encryptionServiceProvider));
});

final unlockVaultUseCaseProvider = Provider<UnlockVault>((ref) {
  return UnlockVault(ref.watch(vaultRepositoryProvider));
});

final saveVaultUseCaseProvider = Provider<SaveVault>((ref) {
  return SaveVault(ref.watch(vaultRepositoryProvider));
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

  @override
  Future<VaultState> build() async => VaultState.locked;

  Future<void> unlock(String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final accounts =
          await ref.read(unlockVaultUseCaseProvider).call(password);

      // Password is kept in-memory only for the active unlocked session.
      _sessionPassword = password;

      return VaultState(
        isUnlocked: true,
        accounts: accounts,
      );
    });
  }

  Future<void> addAccount(Account account) async {
    final current = state.valueOrNull;
    if (current == null || !current.isUnlocked || _sessionPassword == null) {
      return;
    }

    final nextAccounts = [...current.accounts, account];
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(saveVaultUseCaseProvider)
          .call(nextAccounts, _sessionPassword!);
      return current.copyWith(accounts: nextAccounts, clearError: true);
    });
  }

  void lock() {
    // Explicitly clear all in-memory sensitive state on lock.
    _sessionPassword = null;
    state = const AsyncData(VaultState.locked);
  }
}

final vaultControllerProvider =
    AsyncNotifierProvider<VaultController, VaultState>(VaultController.new);
