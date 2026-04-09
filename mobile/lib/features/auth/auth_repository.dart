import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../../core/user_prefs.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});

class VerifyOtpResult {
  const VerifyOtpResult({
    required this.needsProfileName,
    required this.profileName,
  });

  final bool needsProfileName;
  final String profileName;
}

class MyIdentity {
  const MyIdentity({
    required this.name,
    required this.phone,
    required this.clientCode,
    this.avatarUrl,
    this.avatarVersion,
  });

  final String name;
  final String phone;
  final String clientCode;
  /// Относительный путь с API, например `/uploads/avatars/uuid.jpg`.
  final String? avatarUrl;
  final int? avatarVersion;

  bool get hasRemoteAvatar =>
      avatarUrl != null && avatarUrl!.trim().isNotEmpty;
}

/// Сохраняет данные из `/me` в локальные prefs (в т.ч. URL аватара).
Future<void> syncMyIdentityToPrefs(MyIdentity me, UserPrefs prefs) async {
  if (me.name.isNotEmpty) await prefs.setDisplayName(me.name);
  if (me.phone.isNotEmpty) await prefs.setPhone(me.phone);
  if (me.clientCode.isNotEmpty) await prefs.setClientCode(me.clientCode);
  if (me.hasRemoteAvatar) {
    await prefs.setAvatarRemote(
      path: me.avatarUrl!.trim(),
      version: me.avatarVersion ?? 0,
    );
  } else {
    await prefs.clearAvatarRemote();
  }
}

class AuthRepository {
  AuthRepository({required this.dio, required this.storage});

  final Dio dio;
  final TokenStorage storage;

  Future<void> requestOtp({required String phone}) async {
    await dio.post<void>('/auth/request-otp', data: {'phone': phone});
  }

  Future<void> resendOtp({required String phone}) async {
    await dio.post<void>('/auth/resend-otp', data: {'phone': phone});
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {'phone': phone, 'code': code},
    );
    await _saveTokens(res.data);
    final d = res.data ?? {};
    return VerifyOtpResult(
      needsProfileName: d['needsProfileName'] == true,
      profileName: (d['profileName'] as String? ?? '').trim(),
    );
  }

  Future<void> setProfileName({
    required String phone,
    required String name,
  }) async {
    await dio.post<void>('/auth/set-profile-name', data: {
      'phone': phone,
      'name': name.trim(),
    });
  }

  Future<String> changePhone({
    required String currentPhone,
    required String newPhone,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/auth/change-phone',
      data: {'currentPhone': currentPhone, 'newPhone': newPhone},
    );
    final p = (res.data?['phone'] as String? ?? '').trim();
    return p;
  }

  // Backward compatibility with previous screens still in project.
  Future<void> login({required String phone, String? password}) =>
      requestOtp(phone: phone);

  Future<void> registerSendOtp({
    required String name,
    required String phone,
    required String password,
  }) =>
      requestOtp(phone: phone);

  Future<void> registerVerify({
    required String phone,
    required String code,
  }) async {
    await verifyOtp(phone: phone, code: code);
  }

  Future<void> registerResendOtp({required String phone}) =>
      resendOtp(phone: phone);

  Future<void> _saveTokens(Map<String, dynamic>? data) async {
    if (data == null) throw const FormatException('Пустой ответ сервера');
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access == null || refresh == null) {
      throw const FormatException('В ответе нет токенов');
    }
    await storage.writeTokens(accessToken: access, refreshToken: refresh);
  }

  Future<MyIdentity> fetchMyIdentity() async {
    final res = await dio.get<Map<String, dynamic>>('/me');
    final d = res.data ?? const {};
    final rawVer = d['avatarVersion'];
    int? avatarVersion;
    if (rawVer is num) {
      avatarVersion = rawVer.toInt();
    }
    return MyIdentity(
      name: (d['name'] as String? ?? '').trim(),
      phone: (d['phone'] as String? ?? '').trim(),
      clientCode: (d['clientCode'] as String? ?? '').trim().toUpperCase(),
      avatarUrl: (d['avatarUrl'] as String?)?.trim(),
      avatarVersion: avatarVersion,
    );
  }
}

String? _nestMessage(dynamic data) {
  if (data is! Map) return null;
  final m = data['message'];
  if (m is String) return m;
  if (m is List && m.isNotEmpty && m.first is String) return m.first as String;
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
    final m = _nestMessage(data);
    if (m != null) return m;
    if (status == 400) return 'Проверьте введённые данные';
    if (status == 404) return 'Данные не найдены';
    if (status != null) return 'Ошибка сервера ($status)';
  }
  return 'Что-то пошло не так. Попробуйте ещё раз';
}
