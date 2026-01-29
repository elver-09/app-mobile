import 'dart:io';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class PhotoConverterService {
  /// Comprime y convierte una lista de archivos File a base64
  /// Las imágenes se comprimen a un tamaño máximo de 1024x1024 con calidad 70%
  static Future<List<String>> filesToBase64(List<File> files) async {
    final List<String> base64List = [];
    
    for (var file in files) {
      try {
        // Obtener tamaño original
        final originalSize = await file.length();
        print('📸 Procesando foto: ${file.path}');
        print('   Tamaño original: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
        
        // Comprimir imagen
        final compressedBytes = await _compressImage(file);
        
        if (compressedBytes != null) {
          final compressedSize = compressedBytes.length;
          final reduction = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);
          
          print('   Tamaño comprimido: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
          print('   Reducción: $reduction%');
          
          // Convertir a base64
          final base64 = base64Encode(compressedBytes);
          base64List.add(base64);
          print('✅ Foto comprimida y convertida a base64');
        } else {
          // Si falla la compresión, usar imagen original
          print('⚠️ Usando imagen original sin comprimir');
          final bytes = await file.readAsBytes();
          final base64 = base64Encode(bytes);
          base64List.add(base64);
        }
      } catch (e) {
        print('❌ Error al procesar foto: $e');
      }
    }
    
    return base64List;
  }
  
  /// Comprime una imagen reduciendo su tamaño y calidad
  static Future<List<int>?> _compressImage(File file) async {
    try {
      // Generar path temporal para imagen comprimida
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Comprimir imagen
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,           // Calidad 70% (balance entre tamaño y calidad)
        minWidth: 1024,        // Ancho máximo 1024px
        minHeight: 1024,       // Alto máximo 1024px
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        final bytes = await result.readAsBytes();
        // Eliminar archivo temporal
        try {
          await File(result.path).delete();
        } catch (e) {
          // Ignorar si no se puede eliminar
        }
        return bytes;
      }
      
      return null;
    } catch (e) {
      print('⚠️ Error en compresión: $e');
      return null;
    }
  }
}

