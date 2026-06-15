import 'package:connectivity_plus/connectivity_plus.dart';

/// Pequeño wrapper sobre connectivity_plus para saber si hay red y
/// reaccionar a los cambios (recuperación de señal -> disparar sync).
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  /// Emite true cuando hay conexión, false cuando se pierde.
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline);
}
