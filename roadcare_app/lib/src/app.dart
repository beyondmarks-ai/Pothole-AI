import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'store.dart';
import 'theme.dart';

class RoadCareApp extends ConsumerWidget {
  const RoadCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    return MaterialApp(
      title: 'RoadCare AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: user == null ? const LoginScreen() : const HomeShell(),
      ),
    );
  }
}
