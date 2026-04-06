/// Собирайте с `--dart-define-from-file=...` или отдельными `--dart-define`.
/// См. [mobile/config/README.md](config/README.md).
class AppEnv {
  AppEnv._();

  /// `development` | `staging` | `production`
  static const String flavor = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:52247/',
  );

  static bool get isProduction => flavor == 'production';

  static bool get isDevelopment => flavor == 'development';

  /// В production только HTTPS (проверка в debug).
  static bool get apiBaseLooksInsecure =>
      apiBase.startsWith('http://') && !apiBase.contains('127.0.0.1') && !apiBase.contains('localhost');
}
