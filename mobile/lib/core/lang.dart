import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_session.dart';

bool isTajik(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  return container.read(appLanguageProvider) == AppLanguage.tg;
}

String tr(BuildContext context, {required String ru, required String tg}) {
  return isTajik(context) ? tg : ru;
}
