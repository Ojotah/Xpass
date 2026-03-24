import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/vault/presentation/screens/home_screen.dart';
import 'features/vault/presentation/screens/lock_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: LockScreen.routeName,
      routes: {
        LockScreen.routeName: (_) => const LockScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
      },
    );
  }
}
