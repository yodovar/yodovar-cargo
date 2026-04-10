import 'package:flutter_test/flutter_test.dart';

import 'package:yodovar_cargo/app.dart';
import 'package:yodovar_cargo/core/api_client.dart';
import 'package:yodovar_cargo/features/auth/auth_session.dart';

void main() {
  testWidgets('приветственный экран отображается', (WidgetTester tester) async {
    await tester.pumpWidget(
      YodovarApp(
        skipOpeningSplash: true,
        providerOverrides: [
          authSessionProvider.overrideWith(
            (ref) => AuthSessionNotifier.guestForTest(
              ref.watch(tokenStorageProvider),
              ref.watch(userPrefsProvider),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Добро пожаловать в Insof Cargo'), findsOneWidget);
    expect(find.text('Далее'), findsOneWidget);
  });
}
