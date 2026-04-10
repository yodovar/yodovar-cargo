import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';

import '../../core/app_theme.dart';
import '../../core/profile_avatar_display.dart';
import '../../core/profile_avatar_url.dart';
import '../../core/user_prefs.dart';
import '../auth/auth_session.dart';
import 'profile_details_screen.dart';
import 'pickup_points_screen.dart';
import 'prohibited_goods_screen.dart';
import 'settings_screen.dart';
import 'tariffs_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static Future<(String, String, String, Uint8List?, String?)> loadProfile(
    UserPrefs prefs,
  ) async {
    final n = (await prefs.readDisplayName())?.trim();
    final p = (await prefs.readPhone())?.trim();
    final c = (await prefs.readClientCode())?.trim().toUpperCase();
    final (remotePath, remoteVer) = await prefs.readAvatarRemote();
    final avatarNetworkUrl = resolveProfileAvatarUrl(
      relativePath: remotePath,
      versionMs: remoteVer,
    );
    Uint8List? avatarBytes;
    final avatarPath = await prefs.readAvatarPath();
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        final f = File(avatarPath);
        if (await f.exists()) {
          avatarBytes = await f.readAsBytes();
        }
      } catch (_) {
        avatarBytes = null;
      }
    } else {
      final avatarBase64 = await prefs.readAvatarBase64();
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          avatarBytes = base64Decode(avatarBase64);
        } catch (_) {
          avatarBytes = null;
        }
      }
    }
    return (
      (n == null || n.isEmpty) ? 'Пользователь' : n,
      (p == null || p.isEmpty) ? '+992' : p,
      c ?? '',
      avatarBytes,
      avatarNetworkUrl,
    );
  }

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _reloadKey = 0;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPrefsProvider);

    return ColoredBox(
      color: const Color(0xFFF2F4F7),
      child: SafeArea(
        child: FutureBuilder<(String, String, String, Uint8List?, String?)>(
          key: ValueKey(_reloadKey),
          future: ProfileScreen.loadProfile(prefs),
          builder: (context, snap) {
            final name = snap.data?.$1 ?? 'Пользователь';
            final phone = snap.data?.$2 ?? '+992';
            final clientCode = snap.data?.$3 ?? '';
            final avatarBytes = snap.data?.$4;
            final avatarNetworkUrl = snap.data?.$5;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Профиль',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                _MergedDataCard(
                  name: name,
                  phone: phone,
                  clientCode: clientCode,
                  avatarBytes: avatarBytes,
                  avatarNetworkUrl: avatarNetworkUrl,
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) =>
                            ProfileDetailsScreen(name: name, phone: phone),
                      ),
                    );
                    if (changed == true && mounted) {
                      setState(() => _reloadKey++);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _ProfileSection(
                  title: 'Сервисы',
                  children: [
                    _ActionTile(
                      icon: Icons.settings_outlined,
                      title: 'Настройки',
                      subtitle: 'Выход и удаление аккаунта',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionTile(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'Мой пункт выдачи',
                      subtitle: 'Адрес и график выдачи',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PickupPointsScreen(
                              userName: name,
                              userPhone: phone,
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionTile(
                      icon: Icons.price_change_outlined,
                      title: 'Тарифы',
                      subtitle: 'Стоимость доставки и услуги',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TariffsScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Мои заказы',
                      subtitle: 'Список всех отправлений',
                      onTap: () => _showSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ProfileSection(
                  title: 'Полезное',
                  children: [
                    _ActionTile(
                      icon: Icons.do_not_disturb_on_outlined,
                      title: 'Список запрещенных товаров',
                      subtitle: 'Что нельзя отправлять',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProhibitedGoodsScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionTile(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI проверка адреса',
                      subtitle: 'Проверьте корректность адреса склада',
                      onTap: () => _showSoon(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Раздел скоро будет доступен'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MergedDataCard extends StatelessWidget {
  const _MergedDataCard({
    required this.name,
    required this.phone,
    required this.clientCode,
    required this.avatarBytes,
    this.avatarNetworkUrl,
    required this.onTap,
  });

  final String name;
  final String phone;
  final String clientCode;
  final Uint8List? avatarBytes;
  final String? avatarNetworkUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.brandRed, AppTheme.brandRedDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandRed.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ProfileAvatarDisplay(
              radius: 24,
              networkUrl: avatarNetworkUrl,
              memoryBytes: avatarBytes,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (clientCode.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Код: $clientCode',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: clientCode));
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.brandRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.brandRed, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
