import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';

import '../../core/app_theme.dart';
import '../../core/pickup_points.dart';
import '../../core/profile_avatar_display.dart';
import '../../core/profile_avatar_url.dart';
import '../auth/auth_session.dart';
import 'notifications_page.dart';

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
  final _trackCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    ref.listenManual<int>(profileAvatarRevisionProvider, (previous, next) {
      if (previous != next) {
        _loadProfile();
      }
    });
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
      if (cityId != null && pickupPoints.any((e) => e.id == cityId)) {
        _pickupCityId = cityId;
      }
    });
  }

  @override
  void dispose() {
    _trackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Запускаем авто-обновление источника уведомлений, даже если страница
    // уведомлений не открыта: бейдж должен обновляться сам.
    ref.watch(notificationsTickProvider);
    final theme = Theme.of(context);
    final unreadNotifications =
        ref.watch(unreadOrderNotificationsCountProvider).valueOrNull ?? 0;
    return ColoredBox(
      color: const Color(0xFFF2F4F7),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            // stretch: иначе Row+Expanded в _TrackCard получают неограниченную ширину (Web).
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ClientHeaderCard(
                name: (_name ?? '').trim().isEmpty ? 'Пользователь' : _name!.trim(),
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
              const _OrderStatusesShowcase(
                statuses: [
                  _OrderStatusChipData(label: 'Получено в Китае', count: 2),
                  _OrderStatusChipData(label: 'В пути', count: 1),
                  _OrderStatusChipData(label: 'Сортировка', count: 0),
                  _OrderStatusChipData(label: 'Готово к выдаче', count: 1),
                ],
              ),
              const SizedBox(height: 8),
              _QuickGrid(),
              const SizedBox(height: 16),
              _SelectedAddressCard(
                cityId: _pickupCityId,
                userName: _name ?? '',
                userPhone: _phone ?? '',
              ),
              const SizedBox(height: 20),
              _TrackCard(controller: _trackCtrl),
              const SizedBox(height: 20),
              Text(
                'Мои отправления',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D21),
                ),
              ),
              const SizedBox(height: 12),
              _ShipmentPreviewCard(),
              const SizedBox(height: 100),
            ],
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotificationsTap,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Center(
                      child: Text(
                        unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
          const Text(
            'Статусы заказов',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Всего активных: $total',
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
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = widget.statuses;
    if (statuses.isEmpty) {
      return const Text(
        'Статусов пока нет',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 126,
          child: PageView.builder(
            controller: _controller,
            itemCount: statuses.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final s = statuses[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
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
                              'Заказов: ${s.count}',
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
                ),
              );
            },
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
  }
}

class _QuickGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.qr_code_scanner_rounded,
        'Адрес склада',
        'QR и текст для Китая',
      ),
      (
        Icons.inventory_2_rounded,
        'Мои заказы',
        'Статусы посылок',
      ),
      (
        Icons.local_offer_rounded,
        'Тарифы',
        'Цены и условия',
      ),
      (
        Icons.support_agent_rounded,
        'Поддержка',
        'Помощь 24/7',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        for (final (icon, title, sub) in items)
          _QuickTile(icon: icon, title: title, subtitle: sub),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () {},
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
  });

  final String cityId;
  final String userName;
  final String userPhone;

  @override
  Widget build(BuildContext context) {
    final point = pickupById(cityId);
    final addr = pickupAddressText(
      point: point,
      userName: userName,
      userPhone: userPhone,
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
              const Icon(Icons.store_mall_directory_outlined, color: AppTheme.brandRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Выбранный адрес: ${point.city}',
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
                const SnackBar(
                  content: Text('Адрес скопирован'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Копировать'),
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.controller});

  final TextEditingController controller;

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
            'Отследить посылку',
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final screenW = MediaQuery.sizeOf(context).width;
              final w = c.maxWidth.isFinite ? c.maxWidth : screenW;
              final field = TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Трек-номер',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              );
              final btn = FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Найти'),
              );
              // Row+Expanded без конечной ширины ломает Web (unbounded width).
              if (w >= 400) {
                return SizedBox(
                  width: w,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: field),
                      const SizedBox(width: 10),
                      btn,
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field,
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: btn,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShipmentPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.brandRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppTheme.brandRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#983472615',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Статус: на складе в Китае',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2,5 кг  ·  \$12.50',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.brandRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'В пути',
              style: TextStyle(
                color: AppTheme.brandRed,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
