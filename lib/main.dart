import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/vault/presentation/providers/vault_providers.dart';
import 'features/vault/presentation/screens/home_screen.dart';
import 'features/vault/presentation/screens/lock_screen.dart';
import 'features/vault/presentation/screens/setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: XPassApp()));
}

class XPassApp extends StatelessWidget {
  const XPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XPass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 117, 37, 105)),
        useMaterial3: true,
      ),
      home: const AppStartGate(),
      routes: {
        LockScreen.routeName: (_) => const LockScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        SetupScreen.routeName: (_) => const SetupScreen(),
      },
    );
  }
}

class AppStartGate extends ConsumerWidget {
  const AppStartGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsControllerProvider);
    final vaultExists = ref.watch(_vaultExistsProvider);

    return vaultExists.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Could not start app.'))),
      data: (exists) => exists ? const LockScreen() : const SetupScreen(),
    );
  }
}

final _vaultExistsProvider = FutureProvider<bool>((ref) {
  return ref.read(checkVaultExistsUseCaseProvider).call();
});
