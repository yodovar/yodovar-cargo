import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

final ordersSummaryProvider = FutureProvider<OrdersSummaryData>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/orders/summary');
  return OrdersSummaryData.fromJson(res.data ?? const {});
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
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: FilledButton.tonal(
              onPressed: () => ref.invalidate(ordersSummaryProvider),
              child: const Text('Ошибка загрузки. Повторить'),
            ),
          ),
          data: (data) => ListView(
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
                'Проверяйте статусы, фильтруйте отправления и быстро находите нужный заказ.',
                style: TextStyle(color: Colors.grey.shade600, height: 1.25),
              ),
              const SizedBox(height: 18),
              const Text(
                'Статусы заказов',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: data.statuses.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 135,
                ),
                itemBuilder: (context, i) => _OrderStatusCard(item: data.statuses[i]),
              ),
              const SizedBox(height: 14),
              _ActionRowCard(
                icon: Icons.qr_code_2_rounded,
                iconColor: const Color(0xFF1EB980),
                title: 'Ваш уникальный QR-код',
                subtitle: data.qrCode,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _ActionRowCard(
                icon: Icons.search_off_rounded,
                iconColor: const Color(0xFFE35A64),
                title: 'Поиск потерянного товара',
                subtitle: 'Проверьте заказ по трек-коду',
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
      ),
    );
  }
}

class OrdersSummaryData {
  const OrdersSummaryData({required this.qrCode, required this.statuses});

  final String qrCode;
  final List<OrderStatusItem> statuses;

  factory OrdersSummaryData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    int readCount(String key) => (stats[key] as num?)?.toInt() ?? 0;
    return OrdersSummaryData(
      qrCode: (json['qrCode'] as String? ?? 'SF4745').trim(),
      statuses: [
        OrderStatusItem(
          icon: Icons.inventory_2_outlined,
          title: 'Все заказы',
          subtitle: 'Полный список отправлений',
          count: readCount('all'),
          color: const Color(0xFF5B7BFF),
        ),
        OrderStatusItem(
          icon: Icons.verified_outlined,
          title: 'Получено в Китае',
          subtitle: 'Принято на складе',
          count: readCount('receivedChina'),
          color: const Color(0xFF1EB980),
        ),
        OrderStatusItem(
          icon: Icons.local_shipping_outlined,
          title: 'В пути',
          subtitle: 'Международная доставка',
          count: readCount('inTransit'),
          color: const Color(0xFFE38A29),
        ),
        OrderStatusItem(
          icon: Icons.tune_rounded,
          title: 'Сортировка',
          subtitle: 'Обработка на хабе',
          count: readCount('sorting'),
          color: const Color(0xFF8C6BFF),
        ),
        OrderStatusItem(
          icon: Icons.task_alt_rounded,
          title: 'Готово к выдаче',
          subtitle: 'Можно забирать',
          count: readCount('readyPickup'),
          color: const Color(0xFF00A7A0),
        ),
        OrderStatusItem(
          icon: Icons.sync_alt_rounded,
          title: 'Передан курьеру',
          subtitle: 'Курьер уже везет',
          count: readCount('withCourier'),
          color: const Color(0xFF5662D9),
        ),
        OrderStatusItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Неоплаченные',
          subtitle: 'Ожидают оплату',
          count: readCount('unpaid'),
          color: const Color(0xFFE38A29),
        ),
        OrderStatusItem(
          icon: Icons.check_circle_outline_rounded,
          title: 'Полученные',
          subtitle: 'Успешно завершенные',
          count: readCount('completed'),
          color: const Color(0xFF1EB980),
        ),
      ],
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.item});

  final OrderStatusItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
