import 'package:flutter/material.dart';

import 'app.dart';
import 'core/push_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationsService.init();
  runApp(const YodovarApp());
}
