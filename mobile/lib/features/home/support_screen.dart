import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/lang.dart';
import '../../core/responsive.dart';
import 'tariffs_screen.dart';

final supportAdminContactsProvider = FutureProvider<List<SupportContactItem>>((
  ref,
) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<List<dynamic>>('/tariffs/support-contacts');
  final raw = res.data ?? [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(SupportContactItem.fromJson)
      .where(_isAllowedContact)
      .toList(growable: false);
});

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(supportAdminContactsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(tr(context, ru: 'Поддержка', tg: 'Дастгирӣ')),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.brandRed, AppTheme.brandRedDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandRed.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, ru: 'Мы всегда на связи', tg: 'Мо ҳамеша дар тамосем'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          tr(
                            context,
                            ru: 'Выберите удобный канал: мессенджеры, соцсети или звонок.',
                            tg: 'Канали мувофиқро интихоб кунед: мессенҷер, шабака ё занг.',
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  contacts.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => _InfoBlock(
                      title: tr(context, ru: 'Контакты временно недоступны', tg: 'Тамосҳо муваққатан дастнорасанд'),
                      lines: [
                        tr(context, ru: 'Не удалось загрузить контакты из админ-панели.', tg: 'Боркунии тамосҳо аз панели админ нашуд.'),
                        tr(context, ru: 'Проверьте интернет и попробуйте снова.', tg: 'Интернетро санҷида боз кӯшиш кунед.'),
                      ],
                      accent: Color(0xFFE35A64),
                      icon: Icons.wifi_off_rounded,
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return _InfoBlock(
                          title: tr(context, ru: 'Контакты еще не добавлены', tg: 'Тамосҳо ҳанӯз илова нашудаанд'),
                          lines: [
                            tr(context, ru: 'Админ пока не заполнил контакты в веб-панели.', tg: 'Админ ҳоло тамосҳоро дар веб-панел пур накардааст.'),
                            tr(context, ru: 'Зайдите позже или обратитесь к менеджеру.', tg: 'Баъдтар ворид шавед ё ба мудир муроҷиат кунед.'),
                          ],
                          accent: Color(0xFF8C6BFF),
                          icon: Icons.info_outline_rounded,
                        );
                      }
                      return _ContactsGrid(
                        contacts: items
                            .map(_SupportItem.fromAdminContact)
                            .toList(growable: false),
                        onTap: (item) async {
                          final uri = _bestUri(item);
                          await _openUri(context, uri, item.title);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _InfoBlock(
                    title: tr(context, ru: 'Как быстрее получить ответ', tg: 'Чӣ тавр зудтар ҷавоб гирифтан'),
                    lines: [
                      tr(context, ru: 'Укажите трек-код и кратко опишите вопрос.', tg: 'Трек-кодро нависед ва саволро кӯтоҳ шарҳ диҳед.'),
                      tr(context, ru: 'В рабочее время отвечаем обычно за 5-15 минут.', tg: 'Дар вақти корӣ одатан дар 5-15 дақиқа ҷавоб медиҳем.'),
                      tr(context, ru: 'Срочные вопросы лучше отправлять в WhatsApp/Telegram.', tg: 'Саволҳои таъҷилиро беҳтар аст ба WhatsApp/Telegram фиристед.'),
                    ],
                    accent: Color(0xFF1EB980),
                    icon: Icons.tips_and_updates_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUri(BuildContext context, Uri uri, String label) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, ru: 'Не удалось открыть $label', tg: '$label кушода нашуд'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ContactsGrid extends StatelessWidget {
  const _ContactsGrid({
    required this.contacts,
    required this.onTap,
  });

  final List<_SupportItem> contacts;
  final ValueChanged<_SupportItem> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final crossAxisCount = w >= 920 ? 3 : (w >= 620 ? 2 : 1);
        return GridView.builder(
          itemCount: contacts.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 132,
          ),
          itemBuilder: (context, i) {
            final card = contacts[i];
            return _SupportCard(
              title: card.title,
              subtitle: card.subtitle,
              icon: card.icon,
              color: card.color,
              onTap: () => onTap(card),
            );
          },
        );
      },
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.lines,
    required this.accent,
    required this.icon,
  });

  final String title;
  final List<String> lines;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $line',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.28,
                      ),
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

class _SupportItem {
  const _SupportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.uri,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String uri;

  factory _SupportItem.fromAdminContact(SupportContactItem raw) {
    final key = raw.key.toLowerCase();
    final label = raw.label.toLowerCase();
    if (key.contains('whatsapp') || label.contains('whatsapp')) {
      return _SupportItem(
        title: 'WhatsApp',
        subtitle: raw.usernameOrPhone,
        icon: Icons.chat_rounded,
        color: const Color(0xFF25D366),
        uri: raw.webUrl.isNotEmpty ? raw.webUrl : raw.appUrl,
      );
    }
    if (key.contains('telegram') || label.contains('telegram')) {
      return _SupportItem(
        title: 'Telegram',
        subtitle: raw.usernameOrPhone,
        icon: Icons.telegram_rounded,
        color: const Color(0xFF2AABEE),
        uri: raw.webUrl.isNotEmpty ? raw.webUrl : raw.appUrl,
      );
    }
    if (key.contains('instagram') || label.contains('instagram')) {
      return _SupportItem(
        title: 'Instagram',
        subtitle: raw.usernameOrPhone,
        icon: Icons.camera_alt_rounded,
        color: const Color(0xFFE1306C),
        uri: raw.webUrl.isNotEmpty ? raw.webUrl : raw.appUrl,
      );
    }
    return _SupportItem(
      title: raw.label.isEmpty ? 'Телефон' : raw.label,
      subtitle: raw.usernameOrPhone,
      icon: Icons.call_rounded,
      color: const Color(0xFFEF5350),
      uri: raw.appUrl.isNotEmpty ? raw.appUrl : raw.webUrl,
    );
  }
}

bool _isAllowedContact(SupportContactItem item) {
  final key = item.key.toLowerCase();
  final label = item.label.toLowerCase();
  return key.contains('whatsapp') ||
      key.contains('telegram') ||
      key.contains('instagram') ||
      key.contains('phone') ||
      key.contains('call') ||
      label.contains('whatsapp') ||
      label.contains('telegram') ||
      label.contains('instagram') ||
      label.contains('телефон') ||
      label.contains('phone');
}

Uri _bestUri(_SupportItem item) {
  final raw = item.uri.trim();
  if (raw.isEmpty) {
    return Uri(scheme: 'https', host: 'example.com');
  }
  return Uri.parse(raw);
}
