import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../core/push_notifications_service.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session.dart';
import 'channels_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// Нижняя навигация для авторизованного клиента.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _index = 0;
  VoidCallback? _channelPushListener;

  Future<void> _goTab(int i) async {
    if (i == _index) return;
    setState(() => _index = i);
    if (i == 0) {
      ref.read(profileAvatarRevisionProvider.notifier).state++;
    }
    if (i == 2) {
      final prefs = ref.read(userPrefsProvider);
      await prefs.markChannelSeenNow();
      ref.invalidate(channelFeedProvider);
      ref.invalidate(unreadChannelPostsCountProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _channelPushListener = _refreshChannelData;
    PushNotificationsService.channelPostRevision.addListener(
      _channelPushListener!,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIdentity());
  }

  @override
  void dispose() {
    if (_channelPushListener != null) {
      PushNotificationsService.channelPostRevision.removeListener(
        _channelPushListener!,
      );
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshChannelData();
    }
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

  void _refreshChannelData() {
    ref.invalidate(channelFeedProvider);
    ref.invalidate(unreadChannelPostsCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final unreadChannel =
        ref.watch(unreadChannelPostsCountProvider).valueOrNull ?? 0;
    final useRail = useWideNavigation(context);

    final stack = IndexedStack(
      index: _index,
      sizing: StackFit.expand,
      children: const [
        HomeScreen(),
        OrdersScreen(),
        ChannelsScreen(),
        ProfileScreen(),
      ],
    );

    final bottomBar = Container(
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
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Главная',
                  selected: _index == 0,
                  onTap: () {
                    _goTab(0);
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.list_alt_rounded,
                  label: 'Заказы',
                  selected: _index == 1,
                  onTap: () {
                    _goTab(1);
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.campaign_rounded,
                  label: 'Канал',
                  selected: _index == 2,
                  badgeCount: unreadChannel,
                  onTap: () {
                    _goTab(2);
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Профиль',
                  selected: _index == 3,
                  onTap: () {
                    _goTab(3);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (useRail) {
      final railFg = Colors.white;
      final railMuted = Colors.white.withValues(alpha: 0.55);
      return Scaffold(
        body: Row(
          // Без stretch высота Row = max(intrinsic детей); Expanded может получить ~0 и дать «белый» контент.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                _goTab(i);
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppTheme.brandRed,
              indicatorColor: Colors.white.withValues(alpha: 0.22),
              selectedIconTheme: IconThemeData(color: railFg),
              unselectedIconTheme: IconThemeData(color: railMuted),
              selectedLabelTextStyle: TextStyle(
                color: railFg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: railMuted,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.home_rounded),
                  label: Text('Главная'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.list_alt_rounded),
                  label: Text('Заказы'),
                ),
                NavigationRailDestination(
                  icon: _RailChannelIcon(
                    selected: false,
                    badgeCount: unreadChannel,
                  ),
                  selectedIcon: _RailChannelIcon(
                    selected: true,
                    badgeCount: unreadChannel,
                  ),
                  label: const Text('Канал'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_rounded),
                  label: Text('Профиль'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: stack),
          ],
        ),
      );
    }

    return Scaffold(
      body: SizedBox.expand(child: stack),
      bottomNavigationBar: bottomBar,
    );
  }
}

class _RailChannelIcon extends StatelessWidget {
  const _RailChannelIcon({
    required this.selected,
    required this.badgeCount,
  });

  final bool selected;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final c = selected ? Colors.white : Colors.white.withValues(alpha: 0.55);
    return Badge(
      isLabelVisible: badgeCount > 0,
      label: Text(
        badgeCount > 99 ? '99+' : '$badgeCount',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
      child: Icon(Icons.campaign_rounded, color: c),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final c = selected ? Colors.white : Colors.white.withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: c, size: 26),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
