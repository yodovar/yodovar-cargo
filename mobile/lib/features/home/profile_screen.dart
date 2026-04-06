import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../auth/auth_session.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: const Color(0xFFF2F4F7),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Профиль',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppTheme.brandRed.withValues(alpha: 0.12),
                child: const Icon(Icons.person_rounded, color: AppTheme.brandRed),
              ),
              title: const Text('Аккаунт'),
              subtitle: const Text('Настройки появятся позже'),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () async {
                await ref.read(authSessionProvider.notifier).signOut();
              },
              style: FilledButton.styleFrom(
                foregroundColor: AppTheme.brandRed,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}
