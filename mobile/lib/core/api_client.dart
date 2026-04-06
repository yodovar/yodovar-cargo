import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBase,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final t = await storage.readAccess();
        if (t != null && t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

Future<void> refreshSession(TokenStorage storage) async {
  final refresh = await storage.readRefresh();
  if (refresh == null || refresh.isEmpty) return;
  final plain = Dio(BaseOptions(baseUrl: AppEnv.apiBase));
  final res = await plain.post<Map<String, dynamic>>(
    '/auth/refresh',
    data: {'refreshToken': refresh},
  );
  final data = res.data!;
  await storage.writeTokens(
    accessToken: data['accessToken'] as String,
    refreshToken: data['refreshToken'] as String,
  );
}
