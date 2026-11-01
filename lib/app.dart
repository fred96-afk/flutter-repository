import 'package:flutter/material.dart';
import 'package:polleria_movil/api/api_config.dart';
import 'package:polleria_movil/routes.dart';
import 'package:polleria_movil/services/inactivity_service.dart';
import 'package:polleria_movil/services/pusher_service.dart';
import 'package:polleria_movil/theme/app_theme.dart';
import 'package:polleria_movil/theme/theme_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    InactivityService.instance.init();
    PusherService.instance.init();
  }

  @override
  void dispose() {
    PusherService.instance.dispose();
    InactivityService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        ApiConfig.instance,
      ]),
      builder: (context, _) {
        return InactivityDetector(
          child: MaterialApp(
            navigatorKey: InactivityService.instance.navigatorKey,
            title: 'Pollería El Gigante',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeController.instance.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routes: routes,
            initialRoute: ApiConfig.instance.isAuthenticated ? '/home' : '/login',
          ),
        );
      },
    );
  }
}
