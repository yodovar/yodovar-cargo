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
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final req = error.requestOptions;
        final alreadyRetried = req.extra['retried'] == true;
        final isRefreshCall = req.path.contains('/auth/refresh');
        if (status == 401 && !alreadyRetried && !isRefreshCall) {
          try {
            await refreshSession(storage);
            final newAccess = await storage.readAccess();
            final cloned = req.copyWith(
              headers: {
                ...req.headers,
                if (newAccess != null && newAccess.isNotEmpty)
                  'Authorization': 'Bearer $newAccess',
              },
              extra: {...req.extra, 'retried': true},
            );
            final retryRes = await dio.fetch(cloned);
            return handler.resolve(retryRes);
          } catch (_) {
            await storage.clear();
          }
        }
        handler.next(error);
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
