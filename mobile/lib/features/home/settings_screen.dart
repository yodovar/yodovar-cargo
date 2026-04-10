import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../auth/auth_session.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _signOut() async {
    final confirmed = await _confirmSignOutDialog();
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(authSessionProvider.notifier).signOut();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _deleteAccount() async {
    final isTg = ref.read(appLanguageProvider) == AppLanguage.tg;
    final confirmed = await _confirmDeleteDialog();
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTg
              ? 'Ҳазфи аккаунт муваққатан танҳо тавассути дастгирӣ дастрас аст.'
              : 'Удаление аккаунта временно доступно только через поддержку.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _confirmSignOutDialog() {
    final isTg = ref.read(appLanguageProvider) == AppLanguage.tg;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTg ? 'Аз аккаунт бароед?' : 'Выйти из аккаунта?'),
        content: Text(
          isTg
              ? 'Шумо метавонед ҳар вақт дубора ворид шавед.'
              : 'Вы сможете войти снова в любой момент.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: <Widget>[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(isTg ? 'Бекор кардан' : 'Отмена'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(isTg ? 'Баромадан' : 'Выйти'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteDialog() {
    final isTg = ref.read(appLanguageProvider) == AppLanguage.tg;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTg ? 'Аккаунтро нест кунед?' : 'Удалить аккаунт?'),
        content: Text(
          isTg
              ? 'Ин амалро бекор кардан имкон надорад. Ҳамаи маълумоти шумо нест мешавад.'
              : 'Это действие нельзя отменить. Все ваши данные будут удалены.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: <Widget>[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(isTg ? 'Бекор кардан' : 'Отмена'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: const Color(0xFFD84315),
                  ),
                  child: Text(isTg ? 'Нест кардан' : 'Удалить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTg = ref.watch(appLanguageProvider) == AppLanguage.tg;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(isTg ? 'Танзимот' : 'Настройки'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              isTg ? 'Идоракунии аккаунт' : 'Управление аккаунтом',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _busy
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LanguageSelectionScreen(),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, color: AppTheme.brandRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isTg ? 'Интихоби забон' : 'Выбрать язык',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade700),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : _signOut,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.brandRedDark,
              side: BorderSide(color: Colors.grey.shade300),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              _busy
                  ? (isTg ? 'Лутфан интизор шавед...' : 'Подождите...')
                  : (isTg ? 'Баромадан' : 'Выйти'),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : _deleteAccount,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD84315),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(isTg ? 'Нест кардани аккаунт' : 'Удалить аккаунт'),
          ),
        ],
      ),
    );
  }
}
