import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  late AppLanguage _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(appLanguageProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(
            _selected == AppLanguage.tg ? 'Интихоби забон' : 'Выбрать язык'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _LanguageTile(
                  title: 'Русский',
                  selected: _selected == AppLanguage.ru,
                  onTap: () => setState(() => _selected = AppLanguage.ru),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                _LanguageTile(
                  title: 'Таджикский',
                  selected: _selected == AppLanguage.tg,
                  onTap: () => setState(() => _selected = AppLanguage.tg),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(appLanguageProvider.notifier)
                  .setLanguage(_selected);
              final label =
                  _selected == AppLanguage.ru ? 'Русский' : 'Таджикский';
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _selected == AppLanguage.tg
                        ? 'Забон интихоб шуд: $label'
                        : 'Язык выбран: $label',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
                _selected == AppLanguage.tg ? 'Нигоҳ доштан' : 'Сохранить'),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade400,
      ),
    );
  }
}
