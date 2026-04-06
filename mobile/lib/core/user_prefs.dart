import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kDisplayName = 'user_display_name';

/// Локальные предпочтения пользователя (имя для приветствия и т.д.).
class UserPrefs {
  UserPrefs({FlutterSecureStorage? storage})
      : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  Future<void> setDisplayName(String name) async {
    final t = name.trim();
    if (t.isEmpty) return;
    await _s.write(key: _kDisplayName, value: t);
  }

  Future<String?> readDisplayName() => _s.read(key: _kDisplayName);

  Future<void> clearDisplayName() => _s.delete(key: _kDisplayName);
}
