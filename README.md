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

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) — проверка **mobile** и **backend**.

## Публикация на GitHub (приватный репозиторий)

Репозиторий Git уже инициализирован в корне. Один раз войдите в GitHub CLI и создайте удалённый репозиторий:

```bash
cd /Users/a1/Documents/cargo
brew install gh   # если ещё нет
gh auth login
gh repo create yodovar-cargo --private --source=. --remote=origin --push \
  --description "Yodovar Cargo — Flutter + NestJS"
```

Имя `yodovar-cargo` можно заменить на своё. Если репозиторий уже создан на сайте:

```bash
git remote add origin https://github.com/ВАШ_ЛОГИН/ИМЯ_РЕПО.git
git push -u origin main
```
