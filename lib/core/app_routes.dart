import 'package:flutter/material.dart';
import 'package:trainyl_2_0/presentation/screens/login_screen.dart';

class AppRoutes {
  static const String login = '/login';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
  };
}