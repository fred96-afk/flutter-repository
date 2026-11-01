import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/data/app_storage.dart';
import 'package:polleria_movil/theme/theme_controller.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> testBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    testBox = await Hive.openBox<dynamic>('test_box_${DateTime.now().microsecondsSinceEpoch}');
    await AppStorage.initForTesting(testBox);
    ApiConfig.instance.clearAuth();
    ThemeController.instance.setThemeMode(ThemeMode.light, persist: false);
  });

  tearDown(() async {
    await testBox.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppStorage with Hive', () {
    test('persists and restores theme mode', () async {
      // Initially light
      expect(ThemeController.instance.themeMode, ThemeMode.light);

      // Change to dark mode and verify persisted in Hive
      ThemeController.instance.setThemeMode(ThemeMode.dark);
      expect(AppStorage.getThemeMode(), ThemeMode.dark);
      expect(testBox.get(AppStorage.keyThemeMode), 'dark');

      // Reset controller in memory
      ThemeController.instance.setThemeMode(ThemeMode.light, persist: false);
      expect(ThemeController.instance.themeMode, ThemeMode.light);

      // Restore saved settings from Hive
      AppStorage.restoreSavedSettings();
      expect(ThemeController.instance.themeMode, ThemeMode.dark);
    });

    test('toggleTheme persists in Hive', () async {
      ThemeController.instance.setThemeMode(ThemeMode.light);
      expect(AppStorage.getThemeMode(), ThemeMode.light);

      ThemeController.instance.toggleTheme();
      expect(ThemeController.instance.themeMode, ThemeMode.dark);
      expect(AppStorage.getThemeMode(), ThemeMode.dark);
      expect(testBox.get(AppStorage.keyThemeMode), 'dark');

      ThemeController.instance.toggleTheme();
      expect(ThemeController.instance.themeMode, ThemeMode.light);
      expect(AppStorage.getThemeMode(), ThemeMode.light);
      expect(testBox.get(AppStorage.keyThemeMode), 'light');
    });

    test('persists and restores auth token', () async {
      expect(ApiConfig.instance.isAuthenticated, isFalse);
      expect(AppStorage.getAuthToken(), isNull);

      // Set token
      const sampleToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.sample';
      ApiConfig.instance.setAuthToken(sampleToken);

      expect(ApiConfig.instance.isAuthenticated, isTrue);
      expect(ApiConfig.instance.authToken, sampleToken);
      expect(AppStorage.getAuthToken(), sampleToken);
      expect(testBox.get(AppStorage.keyAuthToken), sampleToken);

      // Simulate app restart: clear in-memory config and restore from Hive
      ApiConfig.instance.setAuthToken(null, persist: false);
      expect(ApiConfig.instance.isAuthenticated, isFalse);

      AppStorage.restoreSavedSettings();
      expect(ApiConfig.instance.isAuthenticated, isTrue);
      expect(ApiConfig.instance.authToken, sampleToken);
    });

    test('clearAuth removes token from Hive', () async {
      const sampleToken = 'test-token-to-delete';
      ApiConfig.instance.setAuthToken(sampleToken);
      expect(testBox.get(AppStorage.keyAuthToken), sampleToken);

      ApiConfig.instance.clearAuth();
      expect(ApiConfig.instance.isAuthenticated, isFalse);
      expect(ApiConfig.instance.authToken, isNull);
      expect(AppStorage.getAuthToken(), isNull);
      expect(testBox.containsKey(AppStorage.keyAuthToken), isFalse);
    });

    test('persists custom backend URL', () async {
      const customUrl = 'http://192.168.1.55:5000';
      ApiConfig.instance.baseUrl = customUrl;

      expect(AppStorage.getBaseUrl(), customUrl);
      expect(testBox.get(AppStorage.keyBaseUrl), customUrl);

      // Simulate app restart
      ApiConfig.instance.setBaseUrl('http://default:5000', persist: false);
      expect(ApiConfig.instance.baseUrl, 'http://default:5000');

      AppStorage.restoreSavedSettings();
      expect(ApiConfig.instance.baseUrl, customUrl);
    });

    test('persists and restores user data, cached menu, and table orders in Hive', () async {
      // 1. User data
      final sampleUser = {'id': 1, 'name': 'Mozo Augusto', 'email': 'augusto@polleria.com', 'role': 'Mozo'};
      await AppStorage.setUserData(sampleUser);
      expect(AppStorage.getUserData(), sampleUser);
      expect(testBox.get(AppStorage.keyUserData), sampleUser);

      // 2. Cached menu
      final sampleMenu = [
        {'id': '1', 'name': '1/4 de pollo', 'price': 12.0, 'category': 'polloALaBrasa'},
        {'id': '2', 'name': 'Parrilla', 'price': 18.0, 'category': 'parrillas'},
      ];
      await AppStorage.setCachedMenu(sampleMenu);
      expect(AppStorage.getCachedMenu(), sampleMenu);
      expect(testBox.get(AppStorage.keyCachedMenu), sampleMenu);

      // 3. Table orders
      final sampleOrders = {
        1: [
          {'product': {'id': '1', 'name': '1/4 de pollo', 'price': 12.0, 'category': 'polloALaBrasa'}, 'quantity': 2}
        ],
      };
      await AppStorage.setTableOrders(sampleOrders);
      final retrievedOrders = AppStorage.getTableOrders();
      expect(retrievedOrders, isNotNull);
      expect(retrievedOrders![1], isNotNull);
      expect(retrievedOrders[1]!.first['quantity'], 2);

      // Cleanup user
      await AppStorage.setUserData(null);
      expect(AppStorage.getUserData(), isNull);
    });
  });
}
