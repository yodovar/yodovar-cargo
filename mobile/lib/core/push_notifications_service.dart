import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import 'env.dart';
import 'token_storage.dart';

const _androidChannelId = 'order_status_channel';
const _androidChannelName = 'Статусы заказов';
const _customSoundBase = 'insof_notification';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // ignore
  }
}

class PushNotificationsService {
  PushNotificationsService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _available = false;
  static final ValueNotifier<int> channelPostRevision = ValueNotifier<int>(0);

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) {
      // В этом проекте push реализован только для Android/iOS.
      _available = false;
      return;
    }

    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
      _available = false;
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((message) async {
      await _showLocalNotification(message);
      HapticFeedback.mediumImpact();
      if (message.data['type'] == 'channel_post') {
        channelPostRevision.value = channelPostRevision.value + 1;
      }
    });
  }

  static Future<void> registerTokenToBackend() async {
    try {
      await init();
      if (!_available) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final dio = DioProvider.instance;
      await dio.post<void>(
        '/me/device-token',
        data: {
          'token': token,
          'platform': Platform.isIOS
              ? 'ios'
              : (Platform.isAndroid ? 'android' : 'other'),
        },
      );
    } catch (e) {
      debugPrint('Push token register failed: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _local.initialize(settings);

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: 'Уведомления о новом статусе заказа',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_customSoundBase),
    );
    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Insof Cargo';
    final body = message.notification?.body ?? 'Новое уведомление';
    const android = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_customSoundBase),
    );
    const ios = DarwinNotificationDetails(
      presentSound: true,
      sound: '$_customSoundBase.aiff',
    );
    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
    );
  }
}

/// Lazy singleton holder for a Dio with interceptors from provider tree is unavailable in static.
class DioProvider {
  DioProvider._();
  static final Dio instance = Dio(BaseOptions(baseUrl: AppEnv.apiBase))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storage = TokenStorage();
          final t = await storage.readAccess();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
      ),
    );
}
