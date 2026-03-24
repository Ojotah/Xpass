import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  runApp(const ProviderScope(child: XPassApp()));
}

class XPassApp extends ConsumerStatefulWidget {
  const XPassApp({super.key});

  @override
  ConsumerState<XPassApp> createState() => _XPassAppState();
}

class _XPassAppState extends ConsumerState<XPassApp> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider).valueOrNull ?? AppSettings.defaults;

    return Listener(
      onPointerDown: (_) => ref.read(vaultControllerProvider.notifier).registerInteraction(),
      child: MaterialApp(
        title: 'XPass',
        debugShowCheckedModeBanner: false,
        themeMode: settings.themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 117, 37, 105),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 117, 37, 105),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
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
    final settings = ref.watch(settingsControllerProvider).valueOrNull ?? AppSettings.defaults;
    final existingVaults = ref.watch(_existingVaultsProvider(settings.vaults));

    return existingVaults.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Could not start app.'))),
      data: (vaults) {
        if (vaults.isEmpty) {
          return const SetupScreen();
        }

        return StartupVaultSelectionScreen(vaults: vaults);
      },
    );
  }
}

final _existingVaultsProvider = FutureProvider.family<List<AppVault>, List<AppVault>>((ref, vaults) async {
  final useCase = ref.read(checkVaultExistsUseCaseProvider);
  final existing = <AppVault>[];

  for (final vault in vaults) {
    final exists = await useCase.call(vault.id);
    if (exists) {
      existing.add(vault);
    }
  }

  return existing;
});
