import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/push_notifications_service.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// Нижняя навигация для авторизованного клиента.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  void _goTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    if (i == 0) {
      ref.read(profileAvatarRevisionProvider.notifier).state++;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIdentity());
  }

  Future<void> _syncIdentity() async {
    try {
      final prefs = ref.read(userPrefsProvider);
      final me = await ref.read(authRepositoryProvider).fetchMyIdentity();
      await syncMyIdentityToPrefs(me, prefs);
      await PushNotificationsService.registerTokenToBackend();
      ref.read(profileAvatarRevisionProvider.notifier).state++;
      if (mounted) setState(() {});
    } catch (_) {
      // Не блокируем UI, если сервер временно недоступен.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: IndexedStack(
          index: _index,
          sizing: StackFit.expand,
          children: [
            const HomeScreen(),
            const OrdersScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.brandRed,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Главная',
                  selected: _index == 0,
                  onTap: () => _goTab(0),
                ),
                _NavItem(
                  icon: Icons.list_alt_rounded,
                  label: 'Заказы',
                  selected: _index == 1,
                  onTap: () => _goTab(1),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Профиль',
                  selected: _index == 2,
                  onTap: () => _goTab(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = selected ? Colors.white : Colors.white.withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
