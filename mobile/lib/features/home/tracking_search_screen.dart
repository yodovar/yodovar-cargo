import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/lang.dart';
import 'orders_screen.dart';

class TrackingSearchScreen extends ConsumerStatefulWidget {
  const TrackingSearchScreen({super.key});

  @override
  ConsumerState<TrackingSearchScreen> createState() =>
      _TrackingSearchScreenState();
}

class _TrackingSearchScreenState extends ConsumerState<TrackingSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  bool _searched = false;
  String? _errorText;
  List<OrderRowItem> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoSearch(String value) {
    _debounce?.cancel();
    final normalized = value.trim();
    if (normalized.isEmpty) {
      setState(() {
        _searched = false;
        _errorText = null;
        _results = const [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), _search);
  }

  Future<void> _search() async {
    final code = _controller.text.trim();
    final normalizedCode = code.toUpperCase();
    if (normalizedCode.isEmpty) {
      setState(() {
        _searched = false;
        _errorText = null;
        _results = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _searched = true;
      _errorText = null;
      _results = const [];
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>(
        '/orders/search',
        queryParameters: {'trackingCode': normalizedCode},
      );
      final directMatches = _extractOrdersFromSearchResponse(
        res.data,
        normalizedCode,
      );

      // Всегда подгружаем список заказов пользователя и фильтруем по коду.
      final listRes = await dio.get<Map<String, dynamic>>(
        '/orders',
        queryParameters: {'take': 120},
      );
      final rows = OrderListData.fromJson(listRes.data ?? const {}).items;
      final containsMatches = rows
          .where(
            (row) => row.trackingCode.toUpperCase().contains(normalizedCode),
          )
          .toList(growable: false);

      final merged = <OrderRowItem>[
        ...directMatches,
        ...containsMatches,
      ];
      final unique = _uniqueByTracking(merged);

      if (unique.isEmpty) {
        setState(() {
          _errorText = tr(
            context,
            ru: 'По вашему трек-коду заказ не найден',
            tg: 'Аз рӯи трек-коди шумо фармоиш ёфт нашуд',
          );
        });
        return;
      }

      setState(() => _results = unique);
    } on DioException {
      setState(() {
        _errorText = tr(
          context,
          ru: 'Ошибка поиска. Проверьте интернет и повторите попытку.',
          tg: 'Хатои ҷустуҷӯ. Интернетро санҷида боз кӯшиш кунед.',
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(tr(context, ru: 'Поиск по трек-коду', tg: 'Ҷустуҷӯ бо трек-код')),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Text(
            'Введите трек-код, чтобы найти ваш заказ',
            style: TextStyle(color: Colors.grey.shade700, height: 1.25),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
              _scheduleAutoSearch(_controller.text);
            },
            decoration: InputDecoration(
              hintText: tr(context, ru: 'Например: INS123456', tg: 'Масалан: INS123456'),
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: _loading ? null : _search,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(tr(context, ru: 'Найти', tg: 'Ёфтан')),
            ),
          ),
          if (!_searched && !_loading) ...[
            const SizedBox(height: 14),
            Text(
              tr(context, ru: 'Введите трек-код и нажмите "Найти".', tg: 'Трек-кодро ворид карда "Ёфтан"-ро пахш кунед.'),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: const TextStyle(
                color: Color(0xFFD84315),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _results.length == 1
                  ? tr(context, ru: 'Найденный заказ', tg: 'Фармоиши ёфтшуда')
                  : tr(context, ru: 'Найденные заказы', tg: 'Фармоишҳои ёфтшуда'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ..._results.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SearchResultCard(
                  order: order,
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      barrierColor: Colors.black.withValues(alpha: 0.28),
                      backgroundColor: Colors.transparent,
                      builder: (_) => _OrderDetailsSheet(order: order),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<OrderRowItem> _extractOrdersFromSearchResponse(
  Map<String, dynamic>? data,
  String normalizedCode,
) {
  if (data == null || data.isEmpty) return const [];

  Map<String, dynamic>? pickMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      final out = <String, dynamic>{};
      for (final e in raw.entries) {
        final k = e.key;
        if (k is String) out[k] = e.value;
      }
      return out.isEmpty ? null : out;
    }
    return null;
  }

  final candidates = <Map<String, dynamic>>[];
  final direct = pickMap(data);
  if (direct != null) candidates.add(direct);
  final order = pickMap(data['order']);
  if (order != null) candidates.add(order);
  final item = pickMap(data['item']);
  if (item != null) candidates.add(item);
  final nested = pickMap(data['data']);
  if (nested != null) candidates.add(nested);
  final rows = data['items'];
  if (rows is List) {
    for (final raw in rows) {
      final map = pickMap(raw);
      if (map != null) candidates.add(map);
    }
  }

  final strict = <OrderRowItem>[];
  for (final c in candidates) {
    final row = OrderRowItem.fromJson(c);
    if (row.trackingCode.isNotEmpty &&
        row.trackingCode.toUpperCase() == normalizedCode) {
      strict.add(row);
    }
  }
  if (strict.isNotEmpty) {
    return _uniqueByTracking(strict);
  }

  // Если сервер вернул одиночный заказ без явного compare по коду, всё равно принимаем.
  final fallback = <OrderRowItem>[];
  for (final c in candidates) {
    final row = OrderRowItem.fromJson(c);
    if (row.trackingCode.isNotEmpty) fallback.add(row);
  }
  return _uniqueByTracking(fallback);
}

List<OrderRowItem> _uniqueByTracking(List<OrderRowItem> rows) {
  final out = <OrderRowItem>[];
  final seen = <String>{};
  for (final row in rows) {
    final key = row.trackingCode.toUpperCase();
    if (key.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    out.add(row);
  }
  return out;
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.order, required this.onTap});

  final OrderRowItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weightKg = ((order.weightGrams ?? 0) / 1000).toStringAsFixed(1);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  color: Color(0xFFF57C00), size: 28),
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
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      context,
                      ru: 'Статус: ${_statusLabel(context, order.status)}',
                      tg: 'Ҳолат: ${_statusLabel(context, order.status)}',
                    ),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(context, ru: 'Вес: $weightKg кг', tg: 'Вазн: $weightKg кг'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
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

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({required this.order});

  final OrderRowItem order;

  @override
  Widget build(BuildContext context) {
    final steps = _buildTimeline(context, order);
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
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  tr(context, ru: 'Трек-код', tg: 'Трек-код'),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              order.trackingCode,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              tr(context, ru: 'Навигация по статусу', tg: 'Равиши ҳолат'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...steps,
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
    required this.showLine,
  });

  final bool active;
  final String title;
  final String subtitle;
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
                  color: active
                      ? activeColor.withValues(alpha: 0.15)
                      : const Color(0xFFF3F3F5),
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
                  color:
                      active ? activeColor.withValues(alpha: 0.45) : offColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color:
                      active ? const Color(0xFF1A1D21) : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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

String _statusLabel(BuildContext context, String status) {
  final tg = isTajik(context);
  switch (status) {
    case 'received_china':
      return tg ? 'Дар Чин қабул шуд' : 'Получено в Китае';
    case 'in_transit':
      return tg ? 'Дар роҳ' : 'В пути';
    case 'sorting':
      return tg ? 'Ҷудокунии бор' : 'Сортировка';
    case 'ready_pickup':
      return tg ? 'Омода барои супоридан' : 'Готово к выдаче';
    case 'with_courier':
      return tg ? 'Ба хаткашон дода шуд' : 'Передан курьеру';
    case 'completed':
      return tg ? 'Қабул шуд' : 'Полученные';
    default:
      return status;
  }
}

List<Widget> _buildTimeline(BuildContext context, OrderRowItem order) {
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
    final title = isTajik(context)
        ? ({
            'created': 'Фармоиш эҷод шуд',
            'received_china': 'Дар Чин қабул шуд',
            'in_transit': 'Дар роҳ',
            'sorting': 'Ҷудокунии бор',
            'ready_pickup': 'Омода барои супоридан',
            'with_courier': 'Ба хаткашон дода шуд',
            'completed': 'Гирифта шуд',
          }[key]!)
        : pair.$1;
    final subtitle = isTajik(context)
        ? ({
            'created': 'Дархост сабт шуд',
            'received_china': 'Дар анбор қабул шуд',
            'in_transit': 'Интиқоли байналмилалӣ',
            'sorting': 'Коркард дар марказ',
            'ready_pickup': 'Фармоишро гирифтан мумкин',
            'with_courier': 'Хаткашон мерасонад',
            'completed': 'Фармоиш анҷом шуд',
          }[key]!)
        : pair.$2;
    list.add(
      _TimelineStepRow(
        active: i <= currentRank,
        title: title,
        subtitle: subtitle,
        showLine: i != stepKeys.length - 1,
      ),
    );
  }
  return list;
}
