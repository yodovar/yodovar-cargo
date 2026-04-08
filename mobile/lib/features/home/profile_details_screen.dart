import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_theme.dart';
import '../auth/auth_session.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({
    super.key,
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;

  @override
  ConsumerState<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  Uint8List? _avatarBytes;
  bool _loadingAvatar = true;
  bool _savingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = ref.read(userPrefsProvider);
    final path = await prefs.readAvatarPath();
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) {
          _avatarBytes = await f.readAsBytes();
        }
      } catch (_) {
        _avatarBytes = null;
      }
    } else {
      final base64 = await prefs.readAvatarBase64();
      if (base64 != null && base64.isNotEmpty) {
        try {
          _avatarBytes = base64Decode(base64);
        } catch (_) {
          _avatarBytes = null;
        }
      }
    }
    if (mounted) setState(() => _loadingAvatar = false);
  }

  Future<void> _pickAvatar() async {
    setState(() => _savingAvatar = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 82,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final docsDir = await getApplicationDocumentsDirectory();
      final avatarFile = File('${docsDir.path}/profile_avatar.jpg');
      await avatarFile.writeAsBytes(bytes, flush: true);
      final prefs = ref.read(userPrefsProvider);
      await prefs.setAvatarPath(avatarFile.path);
      // Legacy fallback key clean-up to avoid stale oversized values.
      await prefs.clearAvatarBase64();
      if (!mounted) return;
      setState(() => _avatarBytes = bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Фото профиля обновлено'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось загрузить фото: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final prefs = ref.read(userPrefsProvider);
    final path = await prefs.readAvatarPath();
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {
        // ignore
      }
    }
    await prefs.clearAvatarPath();
    await prefs.clearAvatarBase64();
    if (mounted) setState(() => _avatarBytes = null);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _loadingAvatar
        ? const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
            child: _avatarBytes == null
                ? const Icon(Icons.person_rounded, color: AppTheme.brandRed, size: 40)
                : null,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(title: const Text('Данные профиля')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.brandRed, AppTheme.brandRedDark],
              ),
            ),
            child: Column(
              children: [
                avatar,
                const SizedBox(height: 12),
                const Text(
                  'Фото профиля',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _savingAvatar ? null : _pickAvatar,
                      icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
                      label: Text(
                        _savingAvatar ? 'Загрузка...' : 'Добавить фото',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (_avatarBytes != null)
                      TextButton.icon(
                        onPressed: _savingAvatar ? null : _removeAvatar,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        label: const Text('Удалить', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Мои данные',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _ViewTile(
            icon: Icons.badge_outlined,
            title: 'Имя пользователя',
            subtitle: widget.name,
          ),
          _ViewTile(
            icon: Icons.phone_outlined,
            title: 'Телефон',
            subtitle: widget.phone,
          ),
        ],
      ),
    );
  }
}

class _ViewTile extends StatelessWidget {
  const _ViewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.brandRed),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
