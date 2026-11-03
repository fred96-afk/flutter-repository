import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/app.dart';
import 'package:polleria_movil/theme/theme_controller.dart';

void main() {
  setUp(() {
    ApiConfig.instance.clearAuth();
    ThemeController.instance.setThemeMode(ThemeMode.light);
  });

  testWidgets('El usuario inicia sesión y ve las mesas del local', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());

    expect(find.text('Inicia sesión para continuar'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Augusto');
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Mesa 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Salón Balcón B'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Salón Balcón B'), findsOneWidget);
  });
}
