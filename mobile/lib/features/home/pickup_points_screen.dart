import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/pickup_points.dart';
import '../auth/auth_session.dart';

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedId = pickupPoints.first.id;
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final saved = await ref.read(userPrefsProvider).readPickupCityId();
    if (!mounted) return;
    if (saved != null && pickupPoints.any((e) => e.id == saved)) {
      _selectedId = saved;
    }
    setState(() => _loading = false);
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

    final selected = pickupById(_selectedId);
    final addr = pickupAddressText(
      point: selected,
      userName: widget.userName,
      userPhone: widget.userPhone,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(title: const Text('Пункты выдачи')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Выберите город, и адрес автоматически обновится.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final p in pickupPoints)
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
                  'Адрес для города: ${selected.city}',
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
                      const SnackBar(
                        content: Text('Адрес скопирован'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Копировать адрес'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
