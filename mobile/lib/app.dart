import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_messenger.dart';
import 'core/app_theme.dart';
import 'features/splash/app_opening_gate.dart';

class YodovarApp extends StatelessWidget {
  const YodovarApp({
    super.key,
    this.providerOverrides = const [],
    this.skipOpeningSplash = false,
  });

  final List<Override> providerOverrides;

  /// `true` в тестах — сразу [AuthRoot], без заставки.
  final bool skipOpeningSplash;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: providerOverrides,
      child: MaterialApp(
        title: 'Yodovar Cargo',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: appMessengerKey,
        theme: AppTheme.light,
        home: AppOpeningGate(skipSplash: skipOpeningSplash),
      ),
    );
  }
}
