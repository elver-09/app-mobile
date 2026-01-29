import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoStorageService {
  static const String _photoKeyPrefix = 'order_photos_';
  static const String _commentKeyPrefix = 'order_comment_';

  /// Guarda las rutas de las fotos para una orden específica
  static Future<void> savePhotoPaths(String orderId, List<File> photos) async {
    final prefs = await SharedPreferences.getInstance();
    final photoPaths = photos.map((photo) => photo.path).toList();
    await prefs.setStringList('$_photoKeyPrefix$orderId', photoPaths);
  }

  /// Carga las fotos guardadas para una orden específica
  static Future<List<File>> loadPhotos(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final photoPaths = prefs.getStringList('$_photoKeyPrefix$orderId') ?? [];
    
    // Filtrar solo las fotos que aún existen en el sistema de archivos
    final existingPhotos = <File>[];
    for (final path in photoPaths) {
      final file = File(path);
      if (await file.exists()) {
        existingPhotos.add(file);
      }
    }
    
    // Si algunas fotos ya no existen, actualizar las preferencias
    if (existingPhotos.length != photoPaths.length) {
      await savePhotoPaths(orderId, existingPhotos);
    }
    
    return existingPhotos;
  }

  /// Elimina todas las fotos guardadas para una orden específica
  static Future<void> clearPhotos(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_photoKeyPrefix$orderId');
  }

  /// Elimina una foto específica de la lista de una orden
  static Future<void> removePhoto(String orderId, int photoIndex, List<File> currentPhotos) async {
    if (photoIndex >= 0 && photoIndex < currentPhotos.length) {
      currentPhotos.removeAt(photoIndex);
      await savePhotoPaths(orderId, currentPhotos);
    }
  }

  /// Guarda el comentario para una orden específica
  static Future<void> saveComment(String orderId, String comment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_commentKeyPrefix$orderId', comment);
  }

  /// Carga el comentario guardado para una orden específica
  static Future<String> loadComment(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_commentKeyPrefix$orderId') ?? '';
  }

  /// Elimina el comentario guardado para una orden específica
  static Future<void> clearComment(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_commentKeyPrefix$orderId');
  }
}
