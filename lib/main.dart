import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/app_routes.dart';

/// Tiempo máximo que la app puede estar en segundo plano (bloqueada o
/// minimizada) antes de cerrar la sesión por seguridad. Ajustable.
const Duration kBackgroundLogoutTimeout = Duration(minutes: 15);

/// Navigator global para poder volver al login desde el observador de ciclo
/// de vida (sin importar en qué pantalla esté el usuario).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MainWidget());
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // La app pasó a segundo plano (bloqueo, minimizado): marcamos la hora.
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      if (since != null &&
          DateTime.now().difference(since) >= kBackgroundLogoutTimeout) {
        // Estuvo demasiado tiempo en segundo plano -> cerrar sesión.
        appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trainyl Mobile App',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
