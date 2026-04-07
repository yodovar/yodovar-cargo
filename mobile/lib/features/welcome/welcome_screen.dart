import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../auth/phone_auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pc = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardingData(
      icon: Icons.waving_hand_rounded,
      title: 'Добро пожаловать в Insof Cargo',
      body:
          'Начни покупать из Китая без посредников, предоплат и скрытых комиссий.',
      hint: 'Всё за 3 минуты',
    ),
    _OnboardingData(
      icon: Icons.shopping_bag_rounded,
      title: 'Установи маркет и вставь наш адрес',
      body:
          'Это займёт около 1 минуты. Мы покажем, куда и что вставить правильно.',
      hint: 'Пошаговая инструкция внутри',
    ),
    _OnboardingData(
      icon: Icons.local_shipping_rounded,
      title: 'Условия доставки',
      body:
          'Обычно от 14 до 25 дней после приёма товара на нашем складе в Китае.',
      hint: 'Прозрачные сроки и статусы',
    ),
    _OnboardingData(
      icon: Icons.groups_rounded,
      title: 'С нами заказывают тысячи клиентов',
      body:
          'Надёжная доставка, отслеживание в приложении и поддержка на каждом шаге.',
      hint: 'Готовы начать?',
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PhoneAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final d = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.brandRed.withValues(alpha: 0.16),
                            const Color(0xFFF7F8FA),
                          ],
                        ),
                        border: Border.all(color: const Color(0xFFE9E9E9)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 98,
                                height: 98,
                                decoration: BoxDecoration(
                                  color: AppTheme.brandRed,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.brandRed
                                          .withValues(alpha: 0.3),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(d.icon, color: Colors.white, size: 56),
                              ),
                            ),
                            const SizedBox(height: 26),
                            Text(
                              d.title,
                              style: const TextStyle(
                                fontSize: 28,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              d.body,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              d.hint,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i ? AppTheme.brandRed : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_index < _pages.length - 1)
                    TextButton(
                      onPressed: () {
                        _pc.animateToPage(
                          _pages.length - 1,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      },
                      child: const Text('Пропустить'),
                    )
                  else
                    const SizedBox(width: 88),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(
                      _index == _pages.length - 1
                          ? 'Начать регистрацию'
                          : 'Далее',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.body,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String body;
  final String hint;
}
