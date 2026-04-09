# Firebase Push Setup

Реальная доставка push в закрытом приложении работает только после добавления Firebase конфигов.

## 1) Android

1. Firebase Console -> Project settings -> Android app.
2. Скачайте `google-services.json`.
3. Положите файл в:
   - `mobile/android/app/google-services.json`

## 2) iOS

1. Firebase Console -> Project settings -> iOS app.
2. Скачайте `GoogleService-Info.plist`.
3. Положите файл в:
   - `mobile/ios/Runner/GoogleService-Info.plist`
4. В Xcode убедитесь, что файл добавлен в target `Runner`.

## 3) APNs (для iOS push в фоне/закрытом)

1. Apple Developer -> Keys -> APNs key.
2. Загрузите APNs key в Firebase Cloud Messaging для iOS.

## 4) Кастомный звук

Используется имя: `insof_notification`.

- Android: добавьте файл  
  `mobile/android/app/src/main/res/raw/insof_notification.mp3`
  (или `.wav`, базовое имя то же)
- iOS: добавьте файл  
  `mobile/ios/Runner/insof_notification.aiff`

Если файла звука нет, система может проиграть стандартный звук.

## 5) Backend env

Нужен сервисный аккаунт Firebase:

- `FIREBASE_SERVICE_ACCOUNT_JSON` — JSON сервисного аккаунта одной строкой.

Пример запуска:

```bash
cd backend
npm run prisma:push
npm run start:dev
```

## 6) Проверка

1. Запустите backend.
2. Запустите mobile.
3. Войдите в приложение (токен устройства зарегистрируется в `/me/device-token`).
4. Смените статус заказа (через админку/склад API).
5. Проверьте push:
   - foreground,
   - background,
   - terminated (закрыто).
