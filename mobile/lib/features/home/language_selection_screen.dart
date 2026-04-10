import 'package:flutter/material.dart';

enum AppLanguageChoice { ru, tg }

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  AppLanguageChoice _selected = AppLanguageChoice.ru;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Выбрать язык'),
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
                  selected: _selected == AppLanguageChoice.ru,
                  onTap: () => setState(() => _selected = AppLanguageChoice.ru),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                _LanguageTile(
                  title: 'Таджикский',
                  selected: _selected == AppLanguageChoice.tg,
                  onTap: () => setState(() => _selected = AppLanguageChoice.tg),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final label =
                  _selected == AppLanguageChoice.ru ? 'Русский' : 'Таджикский';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Язык выбран: $label'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Сохранить'),
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
