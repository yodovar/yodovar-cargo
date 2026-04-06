# Yodovar Cargo

Монорепозиторий: **`mobile/`** (Flutter) и **`backend/`** (сейчас только заготовка под API).

## Backend

В `backend/` остались **`backend/.env`** и **`backend/.env.example`**. Исходный код NestJS/Prisma удалён — можно поднять новый стек с нуля.

## Flutter

```bash
cd mobile
flutter pub get
flutter run --dart-define-from-file=config/dart_defines/dev.json
```

Подробнее: [mobile/README.md](mobile/README.md), [mobile/config/README.md](mobile/config/README.md).

## Docker (PostgreSQL)

```bash
docker compose up -d
```

База пригодится, когда появится новый бэкенд.

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) — проверка только **mobile** (`flutter analyze`, `flutter test`).
