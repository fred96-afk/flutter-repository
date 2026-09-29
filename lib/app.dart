import 'package:polleria_movil/routes.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polleria Gigante',
      routes: routes,
      initialRoute: '/',
    );
  }
}
