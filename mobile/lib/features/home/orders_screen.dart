import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api_client.dart';

final ordersSummaryProvider = FutureProvider<OrdersSummaryData>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/orders/summary');
  return OrdersSummaryData.fromJson(res.data ?? const {});
});

final ordersListProvider =
    FutureProvider.family<OrderListData, String?>((ref, statusKey) async {
      final dio = ref.read(dioProvider);
      final q = <String, dynamic>{'take': 100};
      final apiStatus = mapStatusKeyToApi(statusKey);
      if (apiStatus != null && apiStatus.isNotEmpty) {
        q['status'] = apiStatus;
      }
      final res = await dio.get<Map<String, dynamic>>('/orders', queryParameters: q);
      final data = OrderListData.fromJson(res.data ?? const {});
      if (statusKey == 'unpaid') {
        return OrderListData(
          items: data.items.where((e) => !e.isPaid).toList(growable: false),
        );
      }
      return data;
    });

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final TextEditingController _trackingController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _searchTracking() async {
    final code = _trackingController.text.trim();
    if (code.isEmpty) return;
    setState(() => _searching = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>(
        '/orders/search',
        queryParameters: {'trackingCode': code},
      );
      final found = res.data?['found'] == true;
      final message = found
          ? 'Трек ${res.data?['trackingCode']} найден. Статус: ${_statusLabel(res.data?['status'] as String? ?? '')}'
          : 'По трек-коду ничего не найдено';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка поиска. Проверьте связь с сервером.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(ordersSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          children: [
            Text(
              'Заказы',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Видите только свои заказы: трек-коды, статусы и время приёмки.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.25),
            ),
            const SizedBox(height: 18),
            const Text(
              'Статусы заказов',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            summary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: FilledButton.tonal(
                  onPressed: () => ref.invalidate(ordersSummaryProvider),
                  child: const Text('Ошибка загрузки. Повторить'),
                ),
              ),
              data: (data) => GridView.builder(
                itemCount: data.statuses.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 148,
                ),
                itemBuilder: (context, i) => _OrderStatusCard(
                  item: data.statuses[i],
                  selected: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrdersByStatusPage(
                          statusKey: data.statuses[i].statusKey,
                          statusTitle: data.statuses[i].title,
                          accentColor: data.statuses[i].color,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            summary.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => _ActionRowCard(
                icon: Icons.qr_code_2_rounded,
                iconColor: const Color(0xFF1EB980),
                title: 'Ваш уникальный QR-код',
                subtitle: data.qrCode,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ClientQrPage(
                        qrCode: data.qrCode,
                        qrPayload: data.qrPayload,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _ActionRowCard(
              icon: Icons.search_off_rounded,
              iconColor: const Color(0xFFE35A64),
              title: 'Поиск по трек-коду',
              subtitle: 'Проверьте свой заказ',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _TrackSearchBar(
              controller: _trackingController,
              searching: _searching,
              onSubmit: _searchTracking,
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersByStatusPage extends ConsumerWidget {
  const OrdersByStatusPage({
    super.key,
    required this.statusKey,
    required this.statusTitle,
    required this.accentColor,
  });

  final String statusKey;
  final String statusTitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(ordersListProvider(statusKey));
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(statusTitle),
        backgroundColor: Colors.transparent,
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton.tonal(
            onPressed: () => ref.invalidate(ordersListProvider(statusKey)),
            child: const Text('Не удалось загрузить. Повторить'),
          ),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text('По этому статусу заказов нет.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFA726),
                      Color(0xFFF57C00),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Найдено заказов: ${data.items.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...data.items.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OrderModernCard(
                    order: o,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        isDismissible: true,
                        enableDrag: true,
                        barrierColor: Colors.black.withValues(alpha: 0.28),
                        backgroundColor: Colors.transparent,
                        builder: (_) => _OrderDetailsSheet(order: o),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OrdersSummaryData {
  const OrdersSummaryData({
    required this.qrCode,
    required this.qrPayload,
    required this.statuses,
  });

  final String qrCode;
  final String qrPayload;
  final List<OrderStatusItem> statuses;

  factory OrdersSummaryData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    int readCount(String key) => (stats[key] as num?)?.toInt() ?? 0;
    final qrCode = (json['qrCode'] as String? ?? '-----').trim();
    final qrPayload = (json['qrPayload'] as String? ?? '').trim();
    return OrdersSummaryData(
      qrCode: qrCode,
      qrPayload: qrPayload.isEmpty ? qrCode : qrPayload,
      statuses: [
        OrderStatusItem(
          icon: Icons.inventory_2_outlined,
          title: 'Все заказы',
          subtitle: 'Полный список отправлений',
          count: readCount('all'),
          color: const Color(0xFF5B7BFF),
          statusKey: 'all',
        ),
        OrderStatusItem(
          icon: Icons.verified_outlined,
          title: 'Получено в Китае',
          subtitle: 'Принято на складе',
          count: readCount('receivedChina'),
          color: const Color(0xFF1EB980),
          statusKey: 'receivedChina',
        ),
        OrderStatusItem(
          icon: Icons.local_shipping_outlined,
          title: 'В пути',
          subtitle: 'Международная доставка',
          count: readCount('inTransit'),
          color: const Color(0xFFE38A29),
          statusKey: 'inTransit',
        ),
        OrderStatusItem(
          icon: Icons.tune_rounded,
          title: 'Сортировка',
          subtitle: 'Обработка на хабе',
          count: readCount('sorting'),
          color: const Color(0xFF8C6BFF),
          statusKey: 'sorting',
        ),
        OrderStatusItem(
          icon: Icons.task_alt_rounded,
          title: 'Готово к выдаче',
          subtitle: 'Можно забирать',
          count: readCount('readyPickup'),
          color: const Color(0xFF00A7A0),
          statusKey: 'readyPickup',
        ),
        OrderStatusItem(
          icon: Icons.sync_alt_rounded,
          title: 'Передан курьеру',
          subtitle: 'Курьер уже везет',
          count: readCount('withCourier'),
          color: const Color(0xFF5662D9),
          statusKey: 'withCourier',
        ),
        OrderStatusItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Неоплаченные',
          subtitle: 'Ожидают оплату',
          count: readCount('unpaid'),
          color: const Color(0xFFE38A29),
          statusKey: 'unpaid',
        ),
        OrderStatusItem(
          icon: Icons.check_circle_outline_rounded,
          title: 'Полученные',
          subtitle: 'Успешно завершенные',
          count: readCount('completed'),
          color: const Color(0xFF1EB980),
          statusKey: 'completed',
        ),
      ],
    );
  }
}

class OrderListData {
  const OrderListData({required this.items});
  final List<OrderRowItem> items;

  factory OrderListData.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) return const OrderListData(items: []);
    return OrderListData(
      items: raw
          .whereType<Map>()
          .map((e) => OrderRowItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class OrderRowItem {
  const OrderRowItem({
    required this.trackingCode,
    required this.status,
    required this.isPaid,
    required this.weightGrams,
    required this.createdAt,
    required this.updatedAt,
  });

  final String trackingCode;
  final String status;
  final bool isPaid;
  final int? weightGrams;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory OrderRowItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        final d = DateTime.tryParse(value);
        if (d != null) return d;
      }
      return DateTime.now();
    }

    return OrderRowItem(
      trackingCode: (json['trackingCode'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      isPaid: json['isPaid'] == true,
      weightGrams: (json['weightGrams'] as num?)?.toInt(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

class OrderStatusItem {
  const OrderStatusItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.statusKey,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final String statusKey;
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final OrderStatusItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? item.color : Colors.transparent,
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.count}',
                    style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              style: TextStyle(color: Colors.grey.shade600, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRowCard extends StatelessWidget {
  const _ActionRowCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class ClientQrPage extends StatelessWidget {
  const ClientQrPage({super.key, required this.qrCode, required this.qrPayload});

  final String qrCode;
  final String qrPayload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Мой уникальный QR-код'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: qrPayload,
                size: 260,
                eyeStyle: const QrEyeStyle(
                  color: Color(0xFFF57C00),
                  eyeShape: QrEyeShape.square,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  color: Color(0xFF1A1D21),
                  dataModuleShape: QrDataModuleShape.square,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Покажите этот QR на складе',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                qrCode,
                style: const TextStyle(
                  color: Color(0xFFF57C00),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderModernCard extends StatelessWidget {
  const _OrderModernCard({required this.order, required this.onTap});

  final OrderRowItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weightKg = ((order.weightGrams ?? 0) / 1000).toStringAsFixed(1);
    final priceTjs = ((order.weightGrams ?? 0) / 1000 * 27.2).toStringAsFixed(2);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFF57C00), size: 34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.trackingCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Статус: ${_statusLabel(order.status)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    children: [
                      Text(
                        'Вес: $weightKg кг',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Цена: $priceTjs TJS',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Обновлено: ${_formatDate(order.updatedAt)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!order.isPaid)
              const Flexible(
                child: Text(
                  'Не оплачено',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFFD84315),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({required this.order});

  final OrderRowItem order;

  @override
  Widget build(BuildContext context) {
    final steps = _buildTimeline(order);
    final weightKg = ((order.weightGrams ?? 0) / 1000).toStringAsFixed(1);
    final volume = ((order.weightGrams ?? 0) / 1000000).toStringAsFixed(3);
    final priceTjs = ((order.weightGrams ?? 0) / 1000 * 27.2).toStringAsFixed(2);
    return DraggableScrollableSheet(
      initialChildSize: 0.76,
      minChildSize: 0.48,
      maxChildSize: 0.93,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Трек-код',
                  style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
            Text(
              order.trackingCode,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (!order.isPaid) ...[
              const SizedBox(height: 4),
              const Text('Не оплачено', style: TextStyle(color: Color(0xFFD84315), fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Оплатить'),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text('Детали заказа', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                _DetailMiniCard(label: 'Вес', value: '$weightKg кг'),
                const SizedBox(width: 8),
                _DetailMiniCard(label: 'Куб', value: '$volume м³'),
                const SizedBox(width: 8),
                _DetailMiniCard(label: 'Цена', value: '$priceTjs TJS'),
              ],
            ),
            const SizedBox(height: 14),
            ...steps,
          ],
        ),
      ),
    );
  }
}

class _DetailMiniCard extends StatelessWidget {
  const _DetailMiniCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8ED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.showLine,
  });

  final bool active;
  final String title;
  final String subtitle;
  final String timeText;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFFF9800);
    final offColor = Colors.grey.shade300;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: active ? activeColor.withValues(alpha: 0.15) : const Color(0xFFF3F3F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  active ? Icons.check_rounded : Icons.circle_outlined,
                  size: 14,
                  color: active ? activeColor : offColor,
                ),
              ),
              if (showLine)
                Container(
                  width: 2,
                  height: 28,
                  color: active ? activeColor.withValues(alpha: 0.45) : offColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: active ? const Color(0xFF1A1D21) : Colors.grey.shade500,
                      ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeText,
                    style: TextStyle(
                      color: active ? Colors.grey.shade700 : Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackSearchBar extends StatelessWidget {
  const _TrackSearchBar({
    required this.controller,
    required this.searching,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool searching;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSubmit(),
                    decoration: InputDecoration(
                      hintText: 'Введите трек-код',
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: searching ? null : onSubmit,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1EB980),
              borderRadius: BorderRadius.circular(14),
            ),
            child: searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'received_china':
      return 'Получено в Китае';
    case 'in_transit':
      return 'В пути';
    case 'sorting':
      return 'Сортировка';
    case 'ready_pickup':
      return 'Готово к выдаче';
    case 'with_courier':
      return 'Передан курьеру';
    case 'completed':
      return 'Полученные';
    default:
      return status;
  }
}

String _formatDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n < 10 ? '0$n' : '$n';
  return '${two(d.day)}.${two(d.month)}.${d.year}, ${two(d.hour)}:${two(d.minute)}';
}

List<Widget> _buildTimeline(OrderRowItem order) {
  const stepKeys = [
    'created',
    'received_china',
    'in_transit',
    'sorting',
    'ready_pickup',
    'with_courier',
    'completed',
  ];
  const stepTitles = {
    'created': ('Заказ создан', 'Заявка оформлена'),
    'received_china': ('Получено в Китае', 'Принято на складе'),
    'in_transit': ('В пути', 'Международная доставка'),
    'sorting': ('Сортировка', 'Обработка на хабе'),
    'ready_pickup': ('Готово к выдаче', 'Можно получить заказ'),
    'with_courier': ('Передан курьеру', 'Курьер доставляет'),
    'completed': ('Получен', 'Заказ завершен'),
  };
  final statusRank = {
    'created': 0,
    'received_china': 1,
    'in_transit': 2,
    'sorting': 3,
    'ready_pickup': 4,
    'with_courier': 5,
    'completed': 6,
  };
  final currentRank = statusRank[order.status] ?? 1;

  final list = <Widget>[];
  for (var i = 0; i < stepKeys.length; i++) {
    final key = stepKeys[i];
    final pair = stepTitles[key]!;
    final active = i <= currentRank;
    final showLine = i != stepKeys.length - 1;
    final time = active ? _formatDate(i <= 1 ? order.createdAt : order.updatedAt) : 'Ожидается';
    list.add(
      _TimelineStepRow(
        active: active,
        title: pair.$1,
        subtitle: pair.$2,
        timeText: time,
        showLine: showLine,
      ),
    );
  }
  return list;
}

String? mapStatusKeyToApi(String? key) {
  switch (key) {
    case null:
    case 'all':
      return null;
    case 'receivedChina':
      return 'received_china';
    case 'inTransit':
      return 'in_transit';
    case 'sorting':
      return 'sorting';
    case 'readyPickup':
      return 'ready_pickup';
    case 'withCourier':
      return 'with_courier';
    case 'completed':
      return 'completed';
    case 'unpaid':
      return null;
    default:
      return null;
  }
}

