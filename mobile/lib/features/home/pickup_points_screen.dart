import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/lang.dart';
import '../../core/pickup_points.dart';
import '../auth/auth_session.dart';
import 'pickup_points_provider.dart';

class PickupPointsScreen extends ConsumerStatefulWidget {
  const PickupPointsScreen({
    super.key,
    required this.userName,
    required this.userPhone,
  });

  final String userName;
  final String userPhone;

  @override
  ConsumerState<PickupPointsScreen> createState() => _PickupPointsScreenState();
}

class _PickupPointsScreenState extends ConsumerState<PickupPointsScreen> {
  late String _selectedId;
  String _clientCode = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedId = pickupPoints.first.id;
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final prefs = ref.read(userPrefsProvider);
    final saved = await prefs.readPickupCityId();
    final code = await prefs.readClientCode();
    if (!mounted) return;
    if (saved != null && saved.trim().isNotEmpty) {
      _selectedId = saved;
    }
    setState(() {
      _loading = false;
      _clientCode = (code ?? '').trim().toUpperCase();
    });
  }

  Future<void> _select(String id) async {
    setState(() => _selectedId = id);
    await ref.read(userPrefsProvider).setPickupCityId(id);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final points = ref.watch(pickupPointsProvider).valueOrNull ?? pickupPoints;
    final selected = points.firstWhere(
      (p) => p.id == _selectedId,
      orElse: () => points.first,
    );
    final addr = pickupAddressText(
      point: selected,
      userName: widget.userName,
      userPhone: widget.userPhone,
      clientCode: _clientCode,
      isTajik: isTajik(context),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(title: Text(tr(context, ru: 'Пункты выдачи', tg: 'Нуқтаҳои супориш'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(
              context,
              ru: 'Выберите город, и адрес автоматически обновится.',
              tg: 'Шаҳрро интихоб кунед, суроға худкор нав мешавад.',
            ),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _select(p.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: p.id == _selectedId
                          ? AppTheme.brandRed
                          : Colors.grey.shade200,
                      width: p.id == _selectedId ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p.id == _selectedId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: p.id == _selectedId
                            ? AppTheme.brandRed
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.city,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    context,
                    ru: 'Адрес для города: ${selected.city}',
                    tg: 'Суроға барои шаҳр: ${selected.city}',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  addr,
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 12),
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
                  label: Text(tr(context, ru: 'Копировать адрес', tg: 'Нусхаи суроға')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
