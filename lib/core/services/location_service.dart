import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Solicita permisos de ubicación si es necesario
  static Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse || 
              result == LocationPermission.always;
      } else if (permission == LocationPermission.deniedForever) {
        print('❌ Permisos de ubicación denegados permanentemente');
        return false;
      }
      return true;
    } catch (e) {
      print('❌ Error al solicitar permisos: $e');
      return false;
    }
  }

  /// Obtiene la ubicación actual del dispositivo
  static Future<Position?> getCurrentLocation() async {
    try {
      // Verificar permisos
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('❌ No hay permisos de ubicación');
        return null;
      }

      // Verificar si ubicación está habilitada
      final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        print('❌ Servicio de ubicación deshabilitado');
        return null;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print(
        '✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
      return null;
    }
  }
}
