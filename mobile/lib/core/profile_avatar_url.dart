import 'env.dart';

/// Собирает полный URL аватара с сервера (кэш-бастинг по [versionMs]).
String? resolveProfileAvatarUrl({
  required String? relativePath,
  int? versionMs,
}) {
  if (relativePath == null || relativePath.isEmpty) return null;
  final base = AppEnv.apiBase.replaceAll(RegExp(r'/$'), '');
  final p = relativePath.startsWith('/') ? relativePath : '/$relativePath';
  if (versionMs != null) {
    return '$base$p?v=$versionMs';
  }
  return '$base$p';
}
