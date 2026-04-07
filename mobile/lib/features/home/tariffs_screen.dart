import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';

final tariffsProvider = FutureProvider<List<TariffItem>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<List<dynamic>>('/tariffs');
  final data = res.data ?? [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(TariffItem.fromJson)
      .toList(growable: false);
});

final supportContactsProvider = FutureProvider<List<SupportContactItem>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<List<dynamic>>('/tariffs/support-contacts');
  final data = res.data ?? [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(SupportContactItem.fromJson)
      .toList(growable: false);
});

class TariffItem {
  const TariffItem({
    required this.key,
    required this.title,
    required this.pricePerKgUsd,
    required this.pricePerCubicUsd,
    required this.minChargeWeightG,
    required this.etaDaysMin,
    required this.etaDaysMax,
    required this.details,
  });

  final String key;
  final String title;
  final double pricePerKgUsd;
  final double pricePerCubicUsd;
  final int minChargeWeightG;
  final int etaDaysMin;
  final int etaDaysMax;
  final List<TariffDetailItem> details;

  factory TariffItem.fromJson(Map<String, dynamic> json) {
    final detailsRaw = json['details'];
    return TariffItem(
      key: (json['key'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      pricePerKgUsd: (json['pricePerKgUsd'] as num?)?.toDouble() ?? 0,
      pricePerCubicUsd: (json['pricePerCubicUsd'] as num?)?.toDouble() ?? 0,
      minChargeWeightG: (json['minChargeWeightG'] as num?)?.toInt() ?? 0,
      etaDaysMin: (json['etaDaysMin'] as num?)?.toInt() ?? 0,
      etaDaysMax: (json['etaDaysMax'] as num?)?.toInt() ?? 0,
      details: detailsRaw is List
          ? detailsRaw
              .whereType<Map<String, dynamic>>()
              .map(TariffDetailItem.fromJson)
              .where((item) => item.text.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }
}

class TariffDetailItem {
  const TariffDetailItem({required this.icon, required this.text});

  final String icon;
  final String text;

  factory TariffDetailItem.fromJson(Map<String, dynamic> json) {
    return TariffDetailItem(
      icon: (json['icon'] as String? ?? 'info').trim(),
      text: (json['text'] as String? ?? '').trim(),
    );
  }
}

class SupportContactItem {
  const SupportContactItem({
    required this.key,
    required this.label,
    required this.usernameOrPhone,
    required this.appUrl,
    required this.webUrl,
  });

  final String key;
  final String label;
  final String usernameOrPhone;
  final String appUrl;
  final String webUrl;

  factory SupportContactItem.fromJson(Map<String, dynamic> json) {
    return SupportContactItem(
      key: (json['key'] as String? ?? '').trim(),
      label: (json['label'] as String? ?? '').trim(),
      usernameOrPhone: (json['usernameOrPhone'] as String? ?? '').trim(),
      appUrl: (json['appUrl'] as String? ?? '').trim(),
      webUrl: (json['webUrl'] as String? ?? '').trim(),
    );
  }
}

class TariffsScreen extends ConsumerWidget {
  const TariffsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tariffs = ref.watch(tariffsProvider);
    final contacts = ref.watch(supportContactsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(title: const Text('Тарифы')),
      body: tariffs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: _dioMessage(e),
          onRetry: () => ref.invalidate(tariffsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _ErrorState(
              message: 'Тарифы пока не добавлены',
              onRetry: () => ref.invalidate(tariffsProvider),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              if (i < items.length) {
                final tariff = items[i];
                return _TariffCard(
                  item: tariff,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TariffDetailsScreen(item: tariff),
                      ),
                    );
                  },
                );
              }
              return _SupportCard(contacts: contacts);
            },
          );
        },
      ),
    );
  }
}

class _TariffCard extends StatelessWidget {
  const _TariffCard({required this.item, required this.onTap});

  final TariffItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.brandRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.brandRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 кг: \$${item.pricePerKgUsd.toStringAsFixed(1)}  |  1 м3: \$${item.pricePerCubicUsd.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class TariffDetailsScreen extends StatelessWidget {
  const TariffDetailsScreen({super.key, required this.item});

  final TariffItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PriceChip(
                          icon: Icons.scale_rounded,
                          title: 'За 1 кг',
                          value: '\$${item.pricePerKgUsd.toStringAsFixed(1)}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PriceChip(
                          icon: Icons.all_inbox_rounded,
                          title: 'За 1 м3',
                          value: '\$${item.pricePerCubicUsd.toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _BadgeLine(
                    icon: Icons.monitor_weight_outlined,
                    text: 'Минимальный оплачиваемый вес: ${item.minChargeWeightG} г',
                  ),
                  const SizedBox(height: 6),
                  _BadgeLine(
                    icon: Icons.schedule_rounded,
                    text: 'Срок доставки: ${item.etaDaysMin}-${item.etaDaysMax} дней',
                  ),
                  const SizedBox(height: 10),
                  ...item.details.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _BadgeLine(icon: _iconByName(d.icon), text: d.text),
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

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.brandRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.brandRed),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade700)),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeLine extends StatelessWidget {
  const _BadgeLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.brandRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.brandRed),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.contacts});

  final AsyncValue<List<SupportContactItem>> contacts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign_rounded, color: AppTheme.brandRed),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Если у вас большой объем, свяжитесь с нами для индивидуального тарифа',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            contacts.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
              error: (_, __) => const Text('Не удалось загрузить контакты поддержки'),
              data: (items) => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map(
                      (item) => _SupportButton(
                        item: item,
                        onTap: () => _openSupportLink(context, item),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.item, required this.onTap});

  final SupportContactItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.brandRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.brandRed.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_supportIcon(item.key), size: 18, color: AppTheme.brandRed),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconByName(String icon) {
  switch (icon) {
    case 'scale':
      return Icons.scale_rounded;
    case 'inventory_2':
      return Icons.inventory_2_rounded;
    case 'schedule':
      return Icons.schedule_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'local_shipping':
      return Icons.local_shipping_rounded;
    case 'percent':
      return Icons.percent_rounded;
    case 'handshake':
      return Icons.handshake_rounded;
    case 'calendar_month':
      return Icons.calendar_month_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

String _dioMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Нет связи с сервером. Попробуйте позже.';
    }
    return 'Ошибка загрузки тарифов (${error.response?.statusCode ?? 'network'})';
  }
  return 'Не удалось загрузить тарифы';
}

Future<void> _openSupportLink(BuildContext context, SupportContactItem item) async {
  final appUri = Uri.tryParse(item.appUrl);
  final webUri = Uri.tryParse(item.webUrl);
  final openedApp = appUri != null && await launchUrl(appUri);
  if (openedApp) return;
  if (webUri != null && await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
    return;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть ссылку')),
    );
  }
}

IconData _supportIcon(String key) {
  switch (key) {
    case 'instagram':
      return Icons.photo_camera_rounded;
    case 'telegram':
      return Icons.send_rounded;
    case 'whatsapp':
      return Icons.chat_rounded;
    default:
      return Icons.support_agent_rounded;
  }
}
