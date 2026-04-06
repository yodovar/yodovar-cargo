import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/user_prefs.dart';

/// Главная для клиента: быстрые действия, трекинг, список отправлений (пока макет).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.prefs});

  final UserPrefs prefs;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _name;
  final _trackCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final n = await widget.prefs.readDisplayName();
    if (mounted) setState(() => _name = n);
  }

  @override
  void dispose() {
    _trackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = (_name != null && _name!.isNotEmpty)
        ? 'Добро пожаловать, $_name!'
        : 'Добро пожаловать!';

    final topInset = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: const Color(0xFFF2F4F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RedHeaderBar(topInset: topInset),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                // stretch: иначе Row+Expanded в _TrackCard получают неограниченную ширину (Web).
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1D21),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Отслеживайте посылки и управляйте заказами в одном месте.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _QuickGrid(),
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
        ],
      ),
    );
  }
}

class _RedHeaderBar extends StatelessWidget {
  const _RedHeaderBar({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, 8 + topInset, 12, 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brandRed,
              AppTheme.brandRedDark,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.white.withValues(alpha: 0.95),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Душанбе',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: 26,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: const Text(
                          '3',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.brandRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'YODOVAR CARGO',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.98),
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
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
