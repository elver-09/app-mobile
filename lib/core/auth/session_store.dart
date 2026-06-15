import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Sesión guardada en el dispositivo para mantener al conductor logueado
/// aunque el sistema cierre la app en segundo plano (bloqueo, falta de memoria).
class SavedSession {
  final String token;
  final String baseUrl;
  final String db;
  final Map<String, dynamic> driver;

  SavedSession({
    required this.token,
    required this.baseUrl,
    required this.db,
    required this.driver,
  });
}

class SessionStore {
  static const _kToken = 'session_token';
  static const _kBaseUrl = 'session_base_url';
  static const _kDb = 'session_db';
  static const _kDriver = 'session_driver';

  /// Guarda la sesión tras un login exitoso.
  static Future<void> save({
    required String token,
    required String baseUrl,
    required String db,
    required Map<String, dynamic> driver,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kBaseUrl, baseUrl);
    await prefs.setString(_kDb, db);
    await prefs.setString(_kDriver, jsonEncode(driver));
  }

  /// Devuelve la sesión guardada o null si no hay.
  static Future<SavedSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final baseUrl = prefs.getString(_kBaseUrl);
    final db = prefs.getString(_kDb);
    if (token == null || token.isEmpty || baseUrl == null || db == null) {
      return null;
    }
    Map<String, dynamic> driver = {};
    final raw = prefs.getString(_kDriver);
    if (raw != null && raw.isNotEmpty) {
      try {
        driver = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return SavedSession(token: token, baseUrl: baseUrl, db: db, driver: driver);
  }

  /// Borra la sesión (al cerrar sesión).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kBaseUrl);
    await prefs.remove(_kDb);
    await prefs.remove(_kDriver);
  }
}
