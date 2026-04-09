import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/profile_avatar_display.dart';
import '../../core/profile_avatar_url.dart';
import '../auth/auth_repository.dart';
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
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  Uint8List? _avatarBytes;
  String? _avatarNetworkUrl;
  bool _loadingAvatar = true;
  bool _savingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = ref.read(userPrefsProvider);
    final (remotePath, remoteVer) = await prefs.readAvatarRemote();
    final networkUrl = resolveProfileAvatarUrl(
      relativePath: remotePath,
      versionMs: remoteVer,
    );
    Uint8List? avatarBytes;
    final path = await prefs.readAvatarPath();
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) {
          avatarBytes = await f.readAsBytes();
        }
      } catch (_) {
        avatarBytes = null;
      }
    } else {
      final base64 = await prefs.readAvatarBase64();
      if (base64 != null && base64.isNotEmpty) {
        try {
          avatarBytes = base64Decode(base64);
        } catch (_) {
          avatarBytes = null;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _avatarNetworkUrl = networkUrl;
      _avatarBytes = avatarBytes;
      _loadingAvatar = false;
    });
  }

  Future<void> _pickAvatar() async {
    setState(() => _savingAvatar = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final dio = ref.read(dioProvider);
      final filename =
          file.name.trim().isNotEmpty ? file.name.trim() : 'avatar.jpg';
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await dio.post<Map<String, dynamic>>(
        '/me/avatar',
        data: form,
      );
      final d = res.data ?? const {};
      final url = (d['avatarUrl'] as String?)?.trim();
      final rawVer = d['avatarVersion'];
      var version = 0;
      if (rawVer is num) {
        version = rawVer.toInt();
      }
      final prefs = ref.read(userPrefsProvider);
      if (url != null && url.isNotEmpty) {
        await prefs.setAvatarRemote(path: url, version: version);
      }
      await prefs.clearAvatarPath();
      await prefs.clearAvatarBase64();

      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarNetworkUrl = resolveProfileAvatarUrl(
          relativePath: url,
          versionMs: version,
        );
      });
      ref.read(profileAvatarRevisionProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Фото сохранено на сервере'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException ? messageFromDio(e) : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось загрузить фото: $msg'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _savingAvatar = true);
    try {
      final dio = ref.read(dioProvider);
      try {
        await dio.delete<void>('/me/avatar');
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
      }
      final prefs = ref.read(userPrefsProvider);
      final path = await prefs.readAvatarPath();
      if (path != null && path.isNotEmpty) {
        try {
          final f = File(path);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      await prefs.clearAllAvatarLocal();
      if (!mounted) return;
      setState(() {
        _avatarBytes = null;
        _avatarNetworkUrl = null;
      });
      ref.read(profileAvatarRevisionProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Фото профиля удалено'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException ? messageFromDio(e) : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось удалить: $msg'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
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
        : ProfileAvatarDisplay(
            radius: 40,
            networkUrl: _avatarNetworkUrl,
            memoryBytes: _avatarBytes,
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
                const SizedBox(height: 4),
                Text(
                  'Хранится на сервере Insof Cargo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
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
                    if (_avatarBytes != null || _avatarNetworkUrl != null)
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
