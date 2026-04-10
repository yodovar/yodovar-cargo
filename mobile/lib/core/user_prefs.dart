import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kDisplayName = 'user_display_name';
const _kPhone = 'user_phone';
const _kClientCode = 'user_client_code';
const _kAvatarBase64 = 'user_avatar_base64';
const _kAvatarPath = 'user_avatar_path';
const _kAvatarRemotePath = 'user_avatar_remote_path';
const _kAvatarRemoteVer = 'user_avatar_remote_ver';
const _kPickupCityId = 'pickup_city_id';
const _kNotificationsSeenAtMs = 'notifications_seen_at_ms';
const _kChannelSeenAtMs = 'channel_seen_at_ms';
const _kAppLanguage = 'app_language';

/// Локальные предпочтения пользователя (имя/номер/аватар/выбранный пункт выдачи).
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

  Future<void> setPhone(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) return;
    await _s.write(key: _kPhone, value: p);
  }

  Future<String?> readPhone() => _s.read(key: _kPhone);

  Future<void> setClientCode(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return;
    await _s.write(key: _kClientCode, value: c);
  }

  Future<String?> readClientCode() => _s.read(key: _kClientCode);

  Future<void> setAvatarBase64(String base64) async {
    if (base64.trim().isEmpty) return;
    await _s.write(key: _kAvatarBase64, value: base64);
  }

  Future<String?> readAvatarBase64() => _s.read(key: _kAvatarBase64);

  Future<void> setAvatarPath(String path) async {
    final p = path.trim();
    if (p.isEmpty) return;
    await _s.write(key: _kAvatarPath, value: p);
  }

  Future<String?> readAvatarPath() => _s.read(key: _kAvatarPath);

  /// Путь вида `/uploads/avatars/...` и версия для `?v=` (с backend).
  Future<void> setAvatarRemote({
    required String path,
    required int version,
  }) async {
    final p = path.trim();
    if (p.isEmpty) return;
    await _s.write(key: _kAvatarRemotePath, value: p);
    await _s.write(key: _kAvatarRemoteVer, value: '$version');
  }

  Future<(String? path, int? version)> readAvatarRemote() async {
    final p = await _s.read(key: _kAvatarRemotePath);
    final v = await _s.read(key: _kAvatarRemoteVer);
    if (p == null || p.isEmpty) return (null, null);
    return (p, int.tryParse(v ?? ''));
  }

  Future<void> clearAvatarRemote() async {
    await _s.delete(key: _kAvatarRemotePath);
    await _s.delete(key: _kAvatarRemoteVer);
  }

  Future<void> setPickupCityId(String cityId) async {
    await _s.write(key: _kPickupCityId, value: cityId);
  }

  Future<String?> readPickupCityId() => _s.read(key: _kPickupCityId);

  Future<void> setNotificationsSeenAtMs(int ms) =>
      _s.write(key: _kNotificationsSeenAtMs, value: '$ms');

  Future<int?> readNotificationsSeenAtMs() async {
    final v = await _s.read(key: _kNotificationsSeenAtMs);
    return int.tryParse(v ?? '');
  }

  Future<void> markNotificationsSeenNow() =>
      setNotificationsSeenAtMs(DateTime.now().millisecondsSinceEpoch);

  Future<void> setChannelSeenAtMs(int ms) =>
      _s.write(key: _kChannelSeenAtMs, value: '$ms');

  Future<int?> readChannelSeenAtMs() async {
    final v = await _s.read(key: _kChannelSeenAtMs);
    return int.tryParse(v ?? '');
  }

  Future<void> markChannelSeenNow() =>
      setChannelSeenAtMs(DateTime.now().millisecondsSinceEpoch);

  Future<void> setAppLanguageCode(String code) =>
      _s.write(key: _kAppLanguage, value: code);

  Future<String?> readAppLanguageCode() => _s.read(key: _kAppLanguage);

  Future<void> clearDisplayName() => _s.delete(key: _kDisplayName);

  Future<void> clearPhone() => _s.delete(key: _kPhone);

  Future<void> clearClientCode() => _s.delete(key: _kClientCode);

  Future<void> clearAvatarBase64() => _s.delete(key: _kAvatarBase64);

  Future<void> clearAvatarPath() => _s.delete(key: _kAvatarPath);

  Future<void> clearPickupCityId() => _s.delete(key: _kPickupCityId);

  Future<void> clearNotificationsSeenAtMs() =>
      _s.delete(key: _kNotificationsSeenAtMs);

  Future<void> clearChannelSeenAtMs() => _s.delete(key: _kChannelSeenAtMs);

  Future<void> clearAppLanguageCode() => _s.delete(key: _kAppLanguage);

  Future<void> clearAllAvatarLocal() async {
    await clearAvatarBase64();
    await clearAvatarPath();
    await clearAvatarRemote();
  }
}
