import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../../core/user_prefs.dart';

final userPrefsProvider = Provider<UserPrefs>((ref) => UserPrefs());

/// Увеличивайте после смены аватара, чтобы главная перечитала prefs.
final profileAvatarRevisionProvider = StateProvider<int>((ref) => 0);

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AsyncValue<bool>>((ref) {
  return AuthSessionNotifier(
    ref.watch(tokenStorageProvider),
    ref.watch(userPrefsProvider),
  );
});

class AuthSessionNotifier extends StateNotifier<AsyncValue<bool>> {
  AuthSessionNotifier(this._tokens, this._prefs)
      : super(const AsyncValue.loading()) {
    _bootstrap();
  }

  /// Для widget-тестов (без реального secure storage).
  AuthSessionNotifier.guestForTest(this._tokens, this._prefs)
      : super(const AsyncValue.data(false));

  final TokenStorage _tokens;
  final UserPrefs _prefs;

  Future<void> _bootstrap() async {
    final t = await _tokens.readAccess();
    state = AsyncValue.data(t != null && t.isNotEmpty);
  }

  /// После успешного login / register (токены уже записаны).
  Future<void> markSignedIn() async {
    state = const AsyncValue.data(true);
  }

  Future<void> signOut() async {
    await _tokens.clear();
    await _prefs.clearDisplayName();
    await _prefs.clearPhone();
    await _prefs.clearClientCode();
    await _prefs.clearAllAvatarLocal();
    state = const AsyncValue.data(false);
  }

  /// Перечитать токен (например после refresh).
  Future<void> refreshFromStorage() async {
    final t = await _tokens.readAccess();
    state = AsyncValue.data(t != null && t.isNotEmpty);
  }
}
