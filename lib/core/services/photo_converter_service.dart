import 'dart:io';
import 'dart:convert';

class PhotoConverterService {
  /// Convierte una lista de archivos File a base64
  static Future<List<String>> filesToBase64(List<File> files) async {
    final List<String> base64List = [];
    
    for (var file in files) {
      try {
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        base64List.add(base64);
        print('✅ Foto convertida a base64: ${file.path}');
      } catch (e) {
        print('❌ Error al convertir foto: $e');
      }
    }
    
    return base64List;
  }
}
