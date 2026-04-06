import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({required this.dio, required this.storage});

  final Dio dio;
  final TokenStorage storage;

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'phone': phone, 'password': password},
    );
    await _saveTokens(res.data);
  }

  /// Шаг 1 регистрации: SMS с 6-значным кодом.
  Future<void> registerSendOtp({
    required String name,
    required String phone,
    required String password,
  }) async {
    await dio.post<void>(
      '/auth/register/send-otp',
      data: {'name': name, 'phone': phone, 'password': password},
    );
  }

  /// Шаг 2: проверка кода и выдача токенов.
  Future<void> registerVerify({
    required String phone,
    required String code,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/auth/register/verify',
      data: {'phone': phone, 'code': code},
    );
    await _saveTokens(res.data);
  }

  Future<void> registerResendOtp({required String phone}) async {
    await dio.post<void>(
      '/auth/register/resend-otp',
      data: {'phone': phone},
    );
  }

  Future<void> _saveTokens(Map<String, dynamic>? data) async {
    if (data == null) {
      throw const FormatException('Пустой ответ сервера');
    }
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access == null || refresh == null) {
      throw const FormatException('В ответе нет токенов');
    }
    await storage.writeTokens(accessToken: access, refreshToken: refresh);
  }
}

String? _nestMessage(dynamic data) {
  if (data is! Map) return null;
  final m = data['message'];
  if (m is String) return m;
  if (m is List && m.isNotEmpty && m.first is String) {
    return m.first as String;
  }
  return null;
}

String messageFromDio(Object e) {
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Нет связи с сервером. Проверьте интернет и адрес API.';
    }
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final fromNest = _nestMessage(data);
    if (fromNest != null) return fromNest;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    if (status == 401) return 'Неверный телефон или пароль';
    if (status == 400) return 'Проверьте введённые данные';
    if (status == 404) return 'Данные не найдены';
    if (status == 409) return 'Этот номер уже зарегистрирован';
    if (status != null) return 'Ошибка сервера ($status)';
  }
  return 'Что-то пошло не так. Попробуйте ещё раз';
}
