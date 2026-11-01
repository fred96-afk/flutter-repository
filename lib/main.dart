import 'package:flutter/material.dart';
import 'package:polleria_movil/app.dart';
import 'package:polleria_movil/data/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  runApp(const App());
}
