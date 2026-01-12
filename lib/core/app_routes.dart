import 'package:flutter/material.dart';
import 'package:trainyl_2_0/presentation/screens/login_screen.dart';
import 'package:trainyl_2_0/presentation/screens/full_scan.dart';
import 'package:trainyl_2_0/presentation/screens/dashboard_day.dart';

class AppRoutes {
  static const String login = '/login';
  static const String fullScan = '/fullScan';
  static const String dashboardDay = '/dashboardDay';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    fullScan: (context) => const FullScan(),
    dashboardDay: (context) => const DashboardDay(),
  };
}