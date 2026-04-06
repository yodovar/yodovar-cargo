# Yodovar API (NestJS)

REST API для мобильного приложения **один и тот же** для iOS и Android: клиенты ходят на `API_BASE`, публикация в App Store / Google Play на это не влияет.

## Стек

- **NestJS** + **Prisma** + **SQLite** (локально, без Docker).
- В продакшене замените `DATABASE_URL` на **PostgreSQL** и в `prisma/schema.prisma` смените `provider` на `postgresql`, затем `prisma migrate dev`.

## Запуск

```bash
cd backend
cp .env.example .env   # если ещё нет своего .env
npm install
npx prisma generate
npx prisma migrate deploy
npm run start:dev
```

API слушает **`http://127.0.0.1:3000`** (или `PORT` из `.env`).

## Где база данных (как в PHP, но проще для старта)

Здесь не нужен отдельный сервер MySQL, как часто в PHP на хостинге.

- В `.env` указано **`DATABASE_URL="file:./dev.db"`** — это **SQLite**: один файл на диске.
- Файл **`backend/dev.db`** создаётся **сам** после команды **`npx prisma migrate deploy`** (таблицы описаны в `prisma/schema.prisma`).
- Открыть и смотреть данные можно через **`npx prisma studio`** (веб-интерфейс) из папки `backend`.

В продакшене обычно переходят на **PostgreSQL** (отдельный сервис) и меняют `DATABASE_URL` на строку вида `postgresql://...`.

**Телефоны:** принимаются только номера **Таджикистана** в виде **`+992` + 9 цифр** (в приложении код страны зафиксирован, вводятся только 9 цифр).

### Адрес для Flutter

| Где запущено приложение | Что указать в `API_BASE` |
|-------------------------|---------------------------|
| iOS Simulator на Mac    | `http://127.0.0.1:3000` |
| Android Emulator        | `http://10.0.2.2:3000` (доступ к хосту Mac/PC) |
| Реальный телефон в Wi‑Fi | `http://192.168.x.x:3000` (LAN IP вашего компьютера) |

## Эндпоинты (как в приложении)

Регистрация (OTP 6 цифр):

1. `POST /auth/register/send-otp` — `{ "name", "phone", "password" }` → `{ "ok": true }` (SMS через заглушку; в dev смотрите лог сервера или задайте `OTP_DEV_CODE=123456` в `.env`)
2. `POST /auth/register/verify` — `{ "phone", "code" }` (только цифры, длина 6) → `{ accessToken, refreshToken }`
3. `POST /auth/register/resend-otp` — `{ "phone" }` → новый код

Вход:

- `POST /auth/login` — `{ "phone", "password" }` → `{ accessToken, refreshToken }`
- `POST /auth/refresh` — `{ "refreshToken" }` → новая пара токенов

Секреты: **`JWT_SECRET`**, **`JWT_REFRESH_SECRET`** (длинные случайные строки).
