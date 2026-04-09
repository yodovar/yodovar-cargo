import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../auth/auth_session.dart';

final notificationsTickProvider = StreamProvider<int>((ref) async* {
  yield 0;
  var i = 1;
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 8));
    yield i++;
  }
});

final orderNotificationsProvider =
    FutureProvider<List<OrderNotificationItem>>((ref) async {
  // Авто-обновление уведомлений без перезагрузки страницы приложения.
  ref.watch(notificationsTickProvider);
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(
    '/me/notifications',
    queryParameters: {'take': 120},
  );
  final raw = res.data?['items'];
  if (raw is! List) return const [];

  final items = raw
      .whereType<Map>()
      .map((e) => OrderNotificationItem.fromJson(e.cast<String, dynamic>()))
      .where((e) => e.trackingCode.isNotEmpty)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
});

final unreadOrderNotificationsCountProvider = FutureProvider<int>((ref) async {
  final prefs = ref.read(userPrefsProvider);
  final seenAtMs = await prefs.readNotificationsSeenAtMs() ?? 0;
  final items = await ref.watch(orderNotificationsProvider.future);
  return items
      .where((e) => e.createdAt.millisecondsSinceEpoch > seenAtMs)
      .length;
});

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final prefs = ref.read(userPrefsProvider);
      await prefs.markNotificationsSeenNow();
      ref.invalidate(unreadOrderNotificationsCountProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(orderNotificationsProvider);
    final unread = ref.watch(unreadOrderNotificationsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Уведомления'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Text(
            'Уведомления',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Новых: ${unread.valueOrNull ?? 0}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          list.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Center(
              child: FilledButton.tonal(
                onPressed: () => ref.invalidate(orderNotificationsProvider),
                child: const Text('Ошибка загрузки. Повторить'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'Пока нет уведомлений по статусам заказов.',
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationCard(item: n),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final OrderNotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF1A1D21),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(item.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderNotificationItem {
  const OrderNotificationItem({
    required this.id,
    required this.orderId,
    required this.trackingCode,
    required this.status,
    required this.createdAt,
    required this.title,
    required this.body,
  });

  final String id;
  final String orderId;
  final String trackingCode;
  final String status;
  final DateTime createdAt;
  final String title;
  final String body;

  IconData get icon {
    switch (status) {
      case 'received_china':
        return Icons.inventory_2_outlined;
      case 'in_transit':
        return Icons.local_shipping_outlined;
      case 'sorting':
        return Icons.tune_rounded;
      case 'ready_pickup':
        return Icons.task_alt_rounded;
      case 'with_courier':
        return Icons.route_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  factory OrderNotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        final d = DateTime.tryParse(value);
        if (d != null) return d.toLocal();
      }
      return DateTime.now();
    }

    return OrderNotificationItem(
      id: (json['id'] as String? ?? '').trim(),
      orderId: (json['orderId'] as String? ?? '').trim(),
      trackingCode: (json['trackingCode'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      body: (json['body'] as String? ?? '').trim(),
      createdAt: parseDate(json['createdAt']),
    );
  }
}

String _formatDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n < 10 ? '0$n' : '$n';
  return '${two(d.day)}.${two(d.month)}.${d.year}, ${two(d.hour)}:${two(d.minute)}';
}
