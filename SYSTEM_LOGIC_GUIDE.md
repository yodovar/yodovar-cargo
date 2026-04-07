# Yodovar Cargo System Logic Guide

## 1) Цель системы

Единая система для:
- клиентов (мобильное приложение),
- работников в Китае (веб-панель с ограниченной ролью),
- работников в Таджикистане (режим работника в мобильном приложении),
- администраторов (полный веб-доступ).

Все работают с одной базой данных и одним backend API, поэтому изменения сразу синхронизируются между приложением и вебом.

## 2) Технологический стек

- Mobile app: Flutter (Dart)
- Web admin/worker panel: Next.js + TypeScript
- Backend API: NestJS + TypeScript
- ORM: Prisma
- DB:
  - dev: SQLite
  - production: PostgreSQL (обязательно)

## 3) Роли и доступы (RBAC)

### `client`
- Вход по телефону + OTP
- Просмотр своих заказов
- Просмотр/редактирование профиля
- Получение уникального кода и QR-кода
- Выбор пункта выдачи

### `worker_cn` (работник в Китае, веб)
- Приемка товара на складе Китая
- Привязка товара к клиенту по уникальному коду
- Ввод/обновление веса
- Перевод статусов (например, `received_china` -> `in_transit`)
- Без доступа к глобальным настройкам системы

### `worker_tj` (работник в Таджикистане, мобильное приложение)
- Вход в приложение как работник
- Скан QR-кода клиента
- Просмотр товаров клиента, готовых к выдаче
- Отметка выдачи
- Ограниченный доступ только к складским операциям

### `admin`
- Полный доступ
- Управление пользователями, заказами, тарифами, контактами поддержки, настройками
- Управление ролями работников
- Просмотр отчетов и журнала действий

## 4) Уникальный код клиента и QR

Каждый клиент получает уникальный код (например, `SF3456`, `KH7890`) при создании аккаунта.

Правила:
- Код уникален по всей системе
- Код не меняется после создания
- На основе кода генерируется QR
- QR хранится в профиле клиента и показывается в приложении

Использование:
- Клиент показывает QR на складе Таджикистана
- `worker_tj` сканирует QR
- Система открывает карточку клиента и список его товаров для выдачи

## 5) Основные сущности данных (ядро)

Минимальный состав:
- `User`
  - id, phone, name, role, `clientCode` (уникальный, nullable до backfill), createdAt
- `Order` / `Parcel`
  - id, trackingCode, `clientId` (клиент), `status`, `weightGrams`, `isPaid`, `handedOverAt` (выдача в ТЖ), createdAt, updatedAt
- `OrderStatusHistory`
  - id, orderId, fromStatus, toStatus, changedByUserId, changedAt, note
- `Tariff`
  - key, цены/условия, editable from admin
- `SupportContact`
  - instagram/telegram/whatsapp ссылки, editable from admin
- `AuditLog`
  - actorId, action, entityType, entityId, beforeJson, afterJson (смена ролей, статусов заказов, правки тарифов/контактов)

## 6) Жизненный цикл заказа

1. Клиент получает свой уникальный код и QR.
2. На складе Китая `worker_cn` принимает товар:
   - вводит trackingCode,
   - привязывает к clientCode,
   - фиксирует вес.
3. Заказ проходит статусы:
   - `received_china`
   - `in_transit`
   - `sorting`
   - `ready_pickup`
   - `with_courier` (опционально)
   - `completed`
4. В Таджикистане `worker_tj` сканирует QR клиента и выдает товары.
5. Все изменения пишутся в `OrderStatusHistory`.

## 7) API-контракты (минимум для MVP)

### Auth
- `POST /auth/request-otp`
- `POST /auth/verify-otp`
- `POST /auth/refresh`

### Профиль и код клиента (JWT)
- `GET /me` — `clientCode` (уникальный, напр. SF3456), `qrPayload` (строка для генерации QR в приложении)
- `GET /client-codes/:code` — для работников: проверка кода / данных из QR (`worker_tj` | `worker_cn` | `admin`)

### Orders (JWT: client | worker_cn | worker_tj | admin)
- `GET /orders/summary`
- `GET /orders/search?trackingCode=...`

### Orders (JWT: worker_cn | worker_tj | admin)
- `PATCH /orders/:id/status` — общая смена статуса + `AuditLog` (для админа/гибких сценариев)

### Склад КНР `worker_cn` | `admin` (JWT)
- `POST /warehouse-cn/intake` — тело: `trackingCode`, `clientCode`, опционально `weightGrams` — приёмка, привязка к клиенту, статус `received_china`
- `PATCH /warehouse-cn/orders/:id/weight` — тело: `weightGrams`
- `PATCH /warehouse-cn/orders/:id/status` — только статусы: `received_china`, `in_transit`, `sorting`

### Склад ТЖ `worker_tj` | `admin` (JWT)
- `POST /warehouse-tj/scan` — тело: `code` (как в QR или только clientCode) — клиент + список заказов к выдаче
- `GET /warehouse-tj/ready-orders?clientCode=SF3456` — тот же список без POST
- `POST /warehouse-tj/orders/:id/handover` — выдача клиенту: статус `completed`, `handedOverAt` (только если заказ в `ready_pickup` или `with_courier`)

### Admin (JWT: только `admin`)
- `PATCH /admin/users/:id/role` — назначить роль пользователю
- `PATCH /admin/tariffs/:key` — правка тарифа (вместо публичного PATCH)
- `PATCH /admin/support-contacts/:key` — правка контактов поддержки
- `GET /admin/audit?limit=100` — журнал аудита

### Публично (без JWT)
- `GET /tariffs`
- `GET /tariffs/support-contacts`

### Seed первого admin
- Переменная окружения `ADMIN_PHONE` (или fallback `STAFF_ADMIN_PHONE`): при старте backend создаётся пользователь с ролью `admin` или существующий номер повышается до `admin`.

## 8) Логика приложений

## Mobile (client + worker_tj)
- Client mode:
  - профиль, тарифы, пункты выдачи, заказы, QR-код
- Worker TJ mode:
  - отдельный экран сканирования QR
  - выдача товаров по клиенту
- Режим определяется ролью из токена

## Web (admin + worker_cn)
- Единый Next.js проект
- После логина UI и разделы зависят от роли:
  - admin: полный dashboard/CRUD
  - worker_cn: только складские операции

## 9) Пошаговый план внедрения (рекомендуемый порядок)

1. Добавить роли в `User` и RBAC guard/decorator в backend.
2. Добавить `clientCode` и QR-логику для каждого клиента.
3. Нормализовать модель заказа: clientId + status + weight + payment + history.
4. Реализовать worker_cn API (приемка/вес/статусы).
5. Реализовать worker_tj API (scan QR / выдача).
6. Подключить mobile экран заказов и worker-режим к новым endpoint'ам.
7. Создать Next.js админ/worker веб-панель.
8. Добавить admin CRUD для тарифов, контактов, пользователей, заказов.
9. Добавить аудит действий и отчеты.
10. Production hardening (PostgreSQL, backup, monitoring, CI/CD).

## 10) Production требования (обязательно)

- PostgreSQL вместо SQLite
- HTTPS и корректный CORS
- Rate limiting
- Логи и error monitoring
- Регулярные бэкапы БД
- Seed скрипты для первого admin и работников
- Политика приватности и комплаенс для App Store / Play Market

## 11) Что делать прямо сейчас

Текущий правильный старт:
1. Backend RBAC + роли
2. Уникальный код клиента + QR
3. Полноценные worker потоки (CN web и TJ mobile)
4. Только после этого расширять админку и отчеты

Это даст возможность полноценно тестировать бизнес-процесс от приемки товара до выдачи клиенту.
