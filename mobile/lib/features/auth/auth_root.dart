import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/main_shell.dart';
import '../splash/cargo_preloader.dart';
import '../welcome/welcome_screen.dart';
import 'auth_session.dart';

/// Корень: гость → приветствие, авторизован → главная оболочка.
class AuthRoot extends ConsumerWidget {
  const AuthRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return session.when(
      loading: () => const CargoFullScreenLoader(),
      data: (loggedIn) =>
          loggedIn ? const MainShell() : const WelcomeScreen(),
      error: (_, __) => const WelcomeScreen(),
    );
  }
}
