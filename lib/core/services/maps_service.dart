import 'package:url_launcher/url_launcher.dart';

class MapsService {
  /// Abre la ruta completa desde el origen hasta el destino en la app de mapas del dispositivo
  static Future<bool> openRouteInMaps({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String? destinationLabel,
  }) async {
    try {
      // URL para Google Maps con direcciones (ruta)
      final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destinationLat,$destinationLng&travelmode=driving'
      );

      // Intentar abrir en Google Maps
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        print('✅ Ruta abierta en Google Maps');
        return true;
      } else {
        throw Exception('No se puede abrir Google Maps');
      }
    } catch (e) {
      print('❌ Error al abrir la ruta en mapas: $e');
      return false;
    }
  }

  /// Abre solo la ubicación de destino en la app de mapas
  static Future<bool> openLocationInMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      // URL para Google Maps (Android) o Apple Maps (iOS)
      final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
      );
      
      // URL alternativa para la app nativa
      final Uri nativeMapsUri = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude'
      );
      
      // Intentar abrir en la app nativa primero
      if (await canLaunchUrl(nativeMapsUri)) {
        await launchUrl(nativeMapsUri, mode: LaunchMode.externalApplication);
        print('✅ Ubicación abierta en app nativa');
        return true;
      } else if (await canLaunchUrl(googleMapsUri)) {
        // Si no funciona, usar Google Maps web
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        print('✅ Ubicación abierta en Google Maps');
        return true;
      } else {
        throw Exception('No se puede abrir la aplicación de mapas');
      }
    } catch (e) {
      print('❌ Error al abrir la ubicación en mapas: $e');
      return false;
    }
  }
}
