import 'package:polleria_movil/screens/login.dart';
import 'package:polleria_movil/screens/home.dart';
import 'package:polleria_movil/screens/orders.dart';
import 'package:flutter/material.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const LoginScreen(),
  '/login': (context) => const LoginScreen(),
  '/home': (context) => const Home(),
  '/orders/pending': (context) => const OrdersScreen(attended: false),
  '/orders/attended': (context) => const OrdersScreen(attended: true),
};
