import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class CargoPdfSaveResult {
  final String path;
  final bool isPublicDownload;

  const CargoPdfSaveResult({
    required this.path,
    required this.isPublicDownload,
  });
}

/// Almacenamiento persistente de los cargos PDF generados durante el recojo.
///
/// En Android intenta primero la carpeta pública Download/Trainyl/Cargos.
/// En versiones con Scoped Storage donde esa escritura no esté permitida,
/// utiliza el directorio privado persistente de la aplicación como respaldo.
class CargoPdfStorage {
  CargoPdfStorage._();

  static Future<CargoPdfSaveResult> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (Platform.isAndroid) {
      final publicResult = await _trySaveToAndroidDownloads(bytes, fileName);
      if (publicResult != null) return publicResult;
    }

    final databasesPath = await getDatabasesPath();
    final appRoot = Directory(databasesPath).parent;
    final cargoDir = Directory(
      p.join(appRoot.path, 'files', 'Trainyl', 'Cargos'),
    );
    await cargoDir.create(recursive: true);

    final file = await _availableFile(cargoDir, fileName);
    await file.writeAsBytes(bytes, flush: true);
    return CargoPdfSaveResult(path: file.path, isPublicDownload: false);
  }

  static Future<CargoPdfSaveResult?> _trySaveToAndroidDownloads(
    Uint8List bytes,
    String fileName,
  ) async {
    // La mayoría de dispositivos Android montan el almacenamiento compartido
    // aquí. En Android con Scoped Storage puede fallar; el caller hará fallback.
    const candidates = <String>[
      '/storage/emulated/0/Download/Trainyl/Cargos',
      '/sdcard/Download/Trainyl/Cargos',
    ];

    for (final path in candidates) {
      try {
        final dir = Directory(path);
        await dir.create(recursive: true);
        final file = await _availableFile(dir, fileName);
        await file.writeAsBytes(bytes, flush: true);
        if (await file.exists()) {
          return CargoPdfSaveResult(path: file.path, isPublicDownload: true);
        }
      } catch (_) {
        // Scoped Storage puede impedir escritura directa en Download.
      }
    }
    return null;
  }

  static Future<File> _availableFile(Directory dir, String fileName) async {
    final extension = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);
    var candidate = File(p.join(dir.path, fileName));
    var suffix = 2;

    while (await candidate.exists()) {
      candidate = File(
        p.join(dir.path, '${baseName}_$suffix$extension'),
      );
      suffix++;
    }
    return candidate;
  }
}

