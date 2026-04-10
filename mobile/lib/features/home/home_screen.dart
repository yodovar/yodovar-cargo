import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';

import '../../core/app_theme.dart';
import '../../core/lang.dart';
import '../../core/pickup_points.dart';
import '../../core/responsive.dart';
import '../../core/profile_avatar_display.dart';
import '../../core/profile_avatar_url.dart';
import '../auth/auth_session.dart';
import 'notifications_page.dart';
import 'orders_screen.dart';
import 'pickup_points_screen.dart';
import 'pickup_points_provider.dart';
import 'support_screen.dart';
import 'tariffs_screen.dart';
import 'tracking_search_screen.dart';

/// Главная для клиента: быстрые действия, трекинг, список отправлений (пока макет).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _name;
  String? _phone;
  String? _clientCode;
  Uint8List? _avatarBytes;
  String? _avatarNetworkUrl;
  String _pickupCityId = pickupPoints.first.id;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = ref.read(userPrefsProvider);
    final n = await prefs.readDisplayName();
    final p = await prefs.readPhone();
    final code = await prefs.readClientCode();
    final (remotePath, remoteVer) = await prefs.readAvatarRemote();
    final networkUrl = resolveProfileAvatarUrl(
      relativePath: remotePath,
      versionMs: remoteVer,
    );
    Uint8List? avatarBytes;
    final avatarPath = await prefs.readAvatarPath();
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        final f = File(avatarPath);
        if (await f.exists()) {
          avatarBytes = await f.readAsBytes();
        }
      } catch (_) {
        avatarBytes = null;
      }
    } else {
      final avatarBase64 = await prefs.readAvatarBase64();
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          avatarBytes = base64Decode(avatarBase64);
        } catch (_) {
          avatarBytes = null;
        }
      }
    }
    final cityId = await prefs.readPickupCityId();
    if (!mounted) return;
    setState(() {
      _name = n;
      _phone = p;
      _clientCode = code;
      _avatarNetworkUrl = networkUrl;
      _avatarBytes = avatarBytes;
      if (cityId != null && cityId.trim().isNotEmpty) {
        _pickupCityId = cityId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // listen только из build — иначе listenManual в initState без отписки даёт
    // «dependent is not a descendant» в InheritedElement.notifyClients.
    ref.listen<int>(profileAvatarRevisionProvider, (previous, next) {
      if (previous != next) {
        _loadProfile();
      }
    });
    final unreadNotifications =
        ref.watch(unreadOrderNotificationsCountProvider).valueOrNull ?? 0;
    final points = ref.watch(pickupPointsProvider).valueOrNull ?? pickupPoints;
    final safeCityId = points.any((e) => e.id == _pickupCityId)
        ? _pickupCityId
        : points.first.id;
    return ColoredBox(
      color: const Color(0xFFF2F4F7),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
              child: Column(
                // stretch: иначе Row+Expanded в _TrackCard получают неограниченную ширину (Web).
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClientHeaderCard(
                    name: (_name ?? '').trim().isEmpty
                        ? tr(context, ru: 'Пользователь', tg: 'Корбар')
                        : _name!.trim(),
                    clientCode: (_clientCode ?? '').trim().isEmpty
                        ? '-----'
                        : _clientCode!.trim().toUpperCase(),
                    avatarBytes: _avatarBytes,
                    avatarNetworkUrl: _avatarNetworkUrl,
                    unreadNotifications: unreadNotifications,
                    onNotificationsTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                      ref.invalidate(unreadOrderNotificationsCountProvider);
                    },
                  ),
                  const SizedBox(height: 14),
                  _OrderStatusesShowcase(
                    statuses: [
                      _OrderStatusChipData(
                        label: tr(context, ru: 'Получено в Китае', tg: 'Дар Чин қабул шуд'),
                        count: 2,
                      ),
                      _OrderStatusChipData(label: tr(context, ru: 'В пути', tg: 'Дар роҳ'), count: 1),
                      _OrderStatusChipData(
                        label: tr(context, ru: 'Сортировка', tg: 'Ҷудокунии бор'),
                        count: 0,
                      ),
                      _OrderStatusChipData(
                        label: tr(context, ru: 'Готово к выдаче', tg: 'Омода барои супоридан'),
                        count: 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _QuickGrid(
                    userName: _name ?? '',
                    userPhone: _phone ?? '',
                  ),
                  const SizedBox(height: 16),
                  _SelectedAddressCard(
                    cityId: safeCityId,
                    userName: _name ?? '',
                    userPhone: _phone ?? '',
                    clientCode: _clientCode ?? '',
                    points: points,
                  ),
                  const SizedBox(height: 20),
                  const _TrackCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientHeaderCard extends StatelessWidget {
  const _ClientHeaderCard({
    required this.name,
    required this.clientCode,
    required this.avatarBytes,
    this.avatarNetworkUrl,
    required this.unreadNotifications,
    required this.onNotificationsTap,
  });

  final String name;
  final String clientCode;
  final Uint8List? avatarBytes;
  final String? avatarNetworkUrl;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ProfileAvatarDisplay(
            radius: 30,
            networkUrl: avatarNetworkUrl,
            memoryBytes: avatarBytes,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D21),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clientCode,
                  style: const TextStyle(
                    color: AppTheme.brandRed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onNotificationsTap,
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(Icons.notifications_none_rounded),
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      right: 4,
                      top: 6,
                      child: IgnorePointer(
                        child: Container(
                          constraints:
                              const BoxConstraints(minWidth: 18, minHeight: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Center(
                            child: Text(
                              unreadNotifications > 99
                                  ? '99+'
                                  : '$unreadNotifications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusChipData {
  const _OrderStatusChipData({required this.label, required this.count});
  final String label;
  final int count;
}

class _OrderStatusesShowcase extends StatelessWidget {
  const _OrderStatusesShowcase({required this.statuses});

  final List<_OrderStatusChipData> statuses;

  @override
  Widget build(BuildContext context) {
    final total = statuses.fold<int>(0, (sum, s) => sum + s.count);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, ru: 'Статусы заказов', tg: 'Ҳолатҳои фармоишҳо'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              context,
              ru: 'Всего активных: $total',
              tg: 'Ҳамагӣ фаъол: $total',
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _OrderStatusCarousel(statuses: statuses),
        ],
      ),
    );
  }
}

class _OrderStatusCarousel extends StatefulWidget {
  const _OrderStatusCarousel({required this.statuses});

  final List<_OrderStatusChipData> statuses;

  @override
  State<_OrderStatusCarousel> createState() => _OrderStatusCarouselState();
}

class _OrderStatusCarouselState extends State<_OrderStatusCarousel> {
  int _currentPage = 0;
  int? _pendingCarouselIndex;
  bool _carouselFrameScheduled = false;

  void _setCarouselPageDeferred(int i) {
    if (i == _currentPage) {
      return;
    }
    _pendingCarouselIndex = i;
    if (_carouselFrameScheduled) {
      return;
    }
    _carouselFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carouselFrameScheduled = false;
      if (!mounted) {
        return;
      }
      final target = _pendingCarouselIndex;
      if (target == null || target == _currentPage) {
        return;
      }
      _pendingCarouselIndex = null;
      setState(() => _currentPage = target);
    });
  }

  Widget _statusCard(_OrderStatusChipData s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    context,
                    ru: 'Заказов: ${s.count}',
                    tg: 'Фармоишҳо: ${s.count}',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = widget.statuses;
    if (statuses.isEmpty) {
      return Text(
        tr(context, ru: 'Статусов пока нет', tg: 'Ҳоло ҳолат нест'),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawW = constraints.maxWidth;
        final viewportW = (!rawW.isFinite || rawW < 80)
            ? MediaQuery.sizeOf(context).width
            : rawW;
        const sep = 10.0;
        final cardW = statusCarouselCardWidth(viewportW);
        final stride = cardW + sep;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
              width: viewportW,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.axis != Axis.horizontal) {
                    return false;
                  }
                  final i = (n.metrics.pixels / stride)
                      .round()
                      .clamp(0, statuses.length - 1);
                  // Синхронный setState здесь на desktop/web даёт рекурсию в MouseTracker.
                  _setCarouselPageDeferred(i);
                  return false;
                },
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: statuses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: sep),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardW,
                      child: _statusCard(statuses[index]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                statuses.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(right: 6),
                  width: _currentPage == i ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({
    required this.userName,
    required this.userPhone,
  });

  final String userName;
  final String userPhone;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.qr_code_scanner_rounded,
        tr(context, ru: 'Адрес склада', tg: 'Суроғаи анбор'),
        tr(context, ru: 'QR и текст для Китая', tg: 'QR ва матн барои Чин'),
        () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PickupPointsScreen(
                userName: userName.trim().isEmpty
                    ? tr(context, ru: 'Пользователь', tg: 'Корбар')
                    : userName,
                userPhone: userPhone.trim().isEmpty ? '+992' : userPhone,
              ),
            ),
          );
        },
      ),
      (
        Icons.inventory_2_rounded,
        tr(context, ru: 'Мои заказы', tg: 'Фармоишҳои ман'),
        tr(context, ru: 'Статусы посылок', tg: 'Ҳолати борҳо'),
        () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const OrdersScreen(),
            ),
          );
        },
      ),
      (
        Icons.local_offer_rounded,
        tr(context, ru: 'Тарифы', tg: 'Тарифҳо'),
        tr(context, ru: 'Цены и условия', tg: 'Нарх ва шартҳо'),
        () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TariffsScreen(),
            ),
          );
        },
      ),
      (
        Icons.support_agent_rounded,
        tr(context, ru: 'Поддержка', tg: 'Дастгирӣ'),
        tr(context, ru: 'Помощь 24/7', tg: 'Кумак 24/7'),
        () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SupportScreen(),
            ),
          );
        },
      ),
    ];

    final w = MediaQuery.sizeOf(context).width;
    final crossCount = w >= 900 ? 4 : (w >= 600 ? 3 : 2);

    return GridView.count(
      crossAxisCount: crossCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        for (final (icon, title, sub, onTap) in items)
          _QuickTile(icon: icon, title: title, subtitle: sub, onTap: onTap),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.brandRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.brandRed, size: 26),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1D21),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedAddressCard extends StatelessWidget {
  const _SelectedAddressCard({
    required this.cityId,
    required this.userName,
    required this.userPhone,
    required this.clientCode,
    required this.points,
  });

  final String cityId;
  final String userName;
  final String userPhone;
  final String clientCode;
  final List<PickupPoint> points;

  @override
  Widget build(BuildContext context) {
    final point = points.firstWhere(
      (p) => p.id == cityId,
      orElse: () => points.first,
    );
    final addr = pickupAddressText(
      point: point,
      userName: userName,
      userPhone: userPhone,
      clientCode: clientCode,
      isTajik: isTajik(context),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_mall_directory_outlined,
                  color: AppTheme.brandRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(
                    context,
                    ru: 'Выбранный адрес: ${point.city}',
                    tg: 'Суроғаи интихобшуда: ${point.city}',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            addr,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: addr));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr(context, ru: 'Адрес скопирован', tg: 'Суроға нусха шуд')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(tr(context, ru: 'Копировать', tg: 'Нусха кардан')),
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(context, ru: 'Поиск по трек-коду', tg: 'Ҷустуҷӯ бо трек-код'),
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              context,
              ru: 'Нажмите, чтобы открыть страницу поиска и найти свой заказ.',
              tg: 'Барои кушодани саҳифаи ҷустуҷӯ ва ёфтани фармоиш пахш кунед.',
            ),
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TrackingSearchScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.travel_explore_rounded,
                    color: Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(context, ru: 'Открыть поиск по трек-коду', tg: 'Кушодани ҷустуҷӯи трек-код'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D21),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade700),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
