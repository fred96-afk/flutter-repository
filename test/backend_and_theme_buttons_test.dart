import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/theme/theme_controller.dart';
import 'package:polleria_movil/widgets/backend_config_button.dart';
import 'package:polleria_movil/widgets/theme_toggle_button.dart';

void main() {
  setUp(() {
    ApiConfig.instance.clearAuth();
    ThemeController.instance.setThemeMode(ThemeMode.light);
    ApiConfig.instance.baseUrl = 'http://10.0.2.2:5000';
  });

  group('BackendConfigButton and BackendConfigDialog', () {
    testWidgets('BackendConfigButton compact variant renders in AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                BackendConfigButton(variant: BackendButtonVariant.compact),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BackendConfigButton), findsOneWidget);
      expect(find.byIcon(Icons.dns_outlined), findsOneWidget);
    });

    testWidgets('BackendConfigButton tonal variant renders formatted host', (tester) async {
      ApiConfig.instance.baseUrl = 'http://192.168.1.100:5000';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackendConfigButton(variant: BackendButtonVariant.tonal),
          ),
        ),
      );

      expect(find.byType(BackendConfigButton), findsOneWidget);
      expect(find.byIcon(Icons.dns_outlined), findsOneWidget);
      expect(find.text('192.168.1.100:5000'), findsOneWidget);
    });

    testWidgets('Tapping BackendConfigButton opens BackendConfigDialog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackendConfigButton(variant: BackendButtonVariant.tonal),
          ),
        ),
      );

      await tester.tap(find.byType(BackendConfigButton));
      await tester.pumpAndSettle();

      expect(find.text('Ajustar Backend API'), findsOneWidget);
      expect(find.text('Atajos rápidos:'), findsOneWidget);
      expect(find.text('Emulador Android (10.0.2.2)'), findsOneWidget);
      expect(find.text('Localhost (5000)'), findsOneWidget);
      expect(find.text('Predeterminado'), findsOneWidget);
      expect(find.text('Probar conexión'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('Applying preset updates URL field and saving updates ApiConfig', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackendConfigButton(variant: BackendButtonVariant.tonal),
          ),
        ),
      );

      await tester.tap(find.byType(BackendConfigButton));
      await tester.pumpAndSettle();

      // Tap Localhost preset
      await tester.tap(find.text('Localhost (5000)'));
      await tester.pumpAndSettle();

      // Tap Guardar
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(ApiConfig.instance.baseUrl, 'http://localhost:5000');
    });

    testWidgets('Canceling dialog does not change ApiConfig', (tester) async {
      ApiConfig.instance.baseUrl = 'http://10.0.2.2:5000';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackendConfigButton(variant: BackendButtonVariant.tonal),
          ),
        ),
      );

      await tester.tap(find.byType(BackendConfigButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Localhost (5000)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(ApiConfig.instance.baseUrl, 'http://10.0.2.2:5000');
    });
  });

  group('ThemeToggleButton adapted variants', () {
    testWidgets('ThemeToggleButton tonal variant displays label and toggles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThemeToggleButton(variant: ThemeButtonVariant.tonal),
          ),
        ),
      );

      expect(find.byType(ThemeToggleButton), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(find.text('Modo oscuro'), findsOneWidget);

      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();

      expect(ThemeController.instance.themeMode, ThemeMode.dark);
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.text('Modo claro'), findsOneWidget);
    });
  });

  group('Backend URL Config File', () {
    test('defaultBackendUrl and BackendUrlConstants are properly defined', () {
      expect(defaultBackendUrl, isNotEmpty);
      expect(defaultBackendUrl.startsWith('http://') || defaultBackendUrl.startsWith('https://'), isTrue);
      expect(backendBaseUrl, isNotEmpty);
      expect(BackendUrlConstants.androidEmulator, 'http://10.0.2.2:5000');
      expect(BackendUrlConstants.localhost, 'http://localhost:5000');
      expect(BackendUrlConstants.platformDefault, isNotEmpty);
    });
  });
}
