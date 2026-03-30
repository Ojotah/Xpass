import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/error/error_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/domain/entities/app_vault.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/vault/presentation/providers/vault_providers.dart';
import 'features/vault/presentation/screens/home_screen.dart';
import 'features/vault/presentation/screens/lock_screen.dart';
import 'features/vault/presentation/screens/setup_screen.dart';
import 'features/vault_switching/presentation/screens/startup_vault_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = ErrorHandler.handleFlutterError;

  runZonedGuarded(
    () {
      runApp(const ProviderScope(child: XPassApp()));
    },
    (error, stackTrace) {
      AppLogger.error(
        'Unhandled zone error',
        error: error,
        stackTrace: stackTrace,
        scope: 'fatal',
      );
    },
  );
}

class XPassApp extends ConsumerStatefulWidget {
  const XPassApp({super.key});

  @override
  ConsumerState<XPassApp> createState() => _XPassAppState();
}

class _XPassAppState extends ConsumerState<XPassApp> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider).valueOrNull ??
        AppSettings.defaults;

    return Listener(
      onPointerDown: (_) =>
          ref.read(vaultControllerProvider.notifier).registerInteraction(),
      child: MaterialApp(
        title: 'XPass Vault',
        debugShowCheckedModeBanner: false,
        themeMode: settings.themeMode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const AppStartGate(),
        routes: {
          LockScreen.routeName: (_) => const LockScreen(),
          HomeScreen.routeName: (_) => const HomeScreen(),
          SetupScreen.routeName: (_) => const SetupScreen(),
        },
      ),
    );
  }
}

class AppStartGate extends ConsumerWidget {
  const AppStartGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).valueOrNull ??
        AppSettings.defaults;
    final startupVaults = ref.watch(_startupVaultsProvider(settings.vaults));

    return startupVaults.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not start app.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(_startupVaultsProvider(settings.vaults)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (vaults) {
        if (vaults.isEmpty) {
          return const SetupScreen();
        }

        return StartupVaultSelectionScreen(vaults: vaults);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - t)),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 56,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'XPass Vault',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure offline storage',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _startupVaultsProvider =
    FutureProvider.family<List<AppVault>, List<AppVault>>((ref, vaults) async {
  /// Keeps the splash from flashing when vault checks finish instantly.
  const minimumSplashDuration = Duration(milliseconds: 400);
  final startedAt = DateTime.now();

  final useCase = ref.read(checkVaultExistsUseCaseProvider);
  final existing = <AppVault>[];

  for (final vault in vaults) {
    final exists = await useCase.call(vault.fileName) ||
        await useCase.call('${vault.id}.dat');
    if (exists) {
      existing.add(vault);
    }
  }

  final elapsed = DateTime.now().difference(startedAt);
  final remaining = minimumSplashDuration - elapsed;
  if (!remaining.isNegative) {
    await Future<void>.delayed(remaining);
  }

  return existing;
});
