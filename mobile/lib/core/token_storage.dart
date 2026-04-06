import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccess = 'access_token';
const _kRefresh = 'refresh_token';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _s.write(key: _kAccess, value: accessToken);
    await _s.write(key: _kRefresh, value: refreshToken);
  }

  Future<String?> readAccess() => _s.read(key: _kAccess);

  Future<String?> readRefresh() => _s.read(key: _kRefresh);

  Future<void> clear() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
  }
}
