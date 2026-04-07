import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kDisplayName = 'user_display_name';
const _kPhone = 'user_phone';
const _kAvatarBase64 = 'user_avatar_base64';
const _kPickupCityId = 'pickup_city_id';

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

  Future<void> setAvatarBase64(String base64) async {
    if (base64.trim().isEmpty) return;
    await _s.write(key: _kAvatarBase64, value: base64);
  }

  Future<String?> readAvatarBase64() => _s.read(key: _kAvatarBase64);

  Future<void> setPickupCityId(String cityId) async {
    await _s.write(key: _kPickupCityId, value: cityId);
  }

  Future<String?> readPickupCityId() => _s.read(key: _kPickupCityId);

  Future<void> clearDisplayName() => _s.delete(key: _kDisplayName);

  Future<void> clearPhone() => _s.delete(key: _kPhone);

  Future<void> clearAvatarBase64() => _s.delete(key: _kAvatarBase64);

  Future<void> clearPickupCityId() => _s.delete(key: _kPickupCityId);
}
