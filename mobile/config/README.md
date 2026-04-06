# Конфигурация сборок Flutter

## Переменные (`--dart-define`)

| Ключ | Назначение |
|------|------------|
| `API_BASE` | Базовый URL API **без** завершающего `/` |
| `APP_ENV` | `development` \| `staging` \| `production` (для assert HTTPS в production) |

## Локально

```bash
flutter run --dart-define-from-file=config/dart_defines/dev.json
```

Android-эмулятор → в `dev.json` укажите `http://10.0.2.2:3000`.

## Release (production)

1. Скопируйте `config/dart_defines/prod.json.example` → **`prod.json`** (не коммитьте секреты; URL API не секрет, но файл удобно держать локально).
2. **Только HTTPS** для `API_BASE` при `APP_ENV=production`.

```bash
flutter build apk --dart-define-from-file=config/dart_defines/prod.json
flutter build ios --dart-define-from-file=config/dart_defines/prod.json
```

Добавьте `prod.json` в `.gitignore`, если не хотите фиксировать URL в репозитории.
