# Yodovar Cargo — Flutter

Экраны в `lib/features/` удалены — добавьте свои страницы в `lib/`. Точка входа: `lib/main.dart`.

**Оставлено для сборки и API (не трогали конфиги платформы):**

- `pubspec.yaml`, `analysis_options.yaml`
- `config/dart_defines/`, `config/README.md`
- `android/`, `ios/`, …
- `lib/core/env.dart`, `lib/core/api_client.dart`, `lib/core/token_storage.dart` — можно использовать при новом UI

## Запуск

```bash
cd mobile
flutter pub get
flutter run --dart-define-from-file=config/dart_defines/dev.json
```

API в другом терминале: `cd ../backend && npm run start:dev`.

На **Android-эмуляторе** в `config/dart_defines/dev.json` укажите `http://10.0.2.2:3000`.

## Сборка без каталогов android/ios

```bash
flutter create . --project-name yodovar_cargo
```

## FCM

После настройки Firebase отправляйте токен на `POST /devices` бэкенда.
