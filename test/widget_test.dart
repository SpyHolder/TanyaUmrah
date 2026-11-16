import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tanya_umrah/providers/auth_provider.dart';
import 'package:tanya_umrah/screens/login_screen.dart';
import 'package:tanya_umrah/screens/splash_screen.dart';

void main() {
  testWidgets('Splash disposes without leaving a navigation timer', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.text('tanyaUMRAH'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Login offers Google only, with no manual identity or host fields',
    (tester) async {
      final auth = AuthProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      expect(find.textContaining('Akun Pengujian'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
