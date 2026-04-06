import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Мягкий градиент сверху
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.brandRed.withValues(alpha: 0.12),
                    AppTheme.surface,
                  ],
                ),
              ),
            ),
          ),
          // Декоративные круги
          Positioned(
            top: -40,
            right: -30,
            child: _BlurCircle(
              size: 140,
              color: AppTheme.brandRed.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: _BlurCircle(
              size: 100,
              color: AppTheme.brandRed.withValues(alpha: 0.06),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  // Логотип-иконка
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandRed.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        size: 44,
                        color: AppTheme.brandRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Yodovar Cargo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: const Color(0xFF1A1A1A),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Доставка из Китая в Таджикистан.\nОтслеживайте посылки в одном приложении.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                          color: Colors.grey.shade700,
                        ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Войти'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Регистрация'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Продолжая, вы соглашаетесь с условиями сервиса',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 8 + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
