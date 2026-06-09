import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Una fila del detalle de escaneo del cargo.
class CargoScanRow {
  final int index;
  final String code;
  final DateTime time;
  final String status;

  CargoScanRow({
    required this.index,
    required this.code,
    required this.time,
    this.status = 'REGISTRADO',
  });
}

/// Genera el "Cargo de Operación" en PDF con la misma estructura del cargo
/// de ejemplo: cabecera TRAINYL, resumen de la operación y detalle de escaneo.
class CargoPdf {
  static final _df = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final _dfHora = DateFormat('HH:mm:ss');

  static final _blue = PdfColor.fromInt(0xFF143A7A);
  static final _blueBright = PdfColor.fromInt(0xFF2C73DE);
  static final _grey = PdfColor.fromInt(0xFF64748B);
  static final _line = PdfColor.fromInt(0xFFE2E8F0);
  static final _rowAlt = PdfColor.fromInt(0xFFF1F5FB);
  static final _ink = PdfColor.fromInt(0xFF0F172A);

  /// Nombre de archivo sugerido: Cargo_<Tienda>_<yyyyMMdd>_<HHmm>.pdf
  static String fileName(String storeName, DateTime termino) {
    final safe = storeName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(termino);
    return 'Cargo_${safe}_$stamp.pdf';
  }

  static Future<Uint8List> build({
    required String storeName,
    required String conductor,
    required String placa,
    required DateTime registro,
    required DateTime termino,
    required int itemsUnicos,
    required int duplicados,
    required List<CargoScanRow> rows,
  }) async {
    final doc = pw.Document();

    final elapsed = termino.difference(registro);
    final mm = elapsed.inMinutes;
    final ss = elapsed.inSeconds % 60;
    final elapsedStr =
        '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    final total = itemsUnicos + duplicados;

    String orDash(String v) => v.trim().isEmpty ? '-' : v.trim();

    pw.Widget kv(String label, String value) => pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: _grey,
                  letterSpacing: 0.4,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                orDash(value),
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );

    pw.Widget kvRow(String l1, String v1, String l2, String v2) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [kv(l1, v1), pw.SizedBox(width: 18), kv(l2, v2)],
          ),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        build: (context) => [
          // ── Cabecera TRAINYL ────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
                colors: [_blueBright, _blue],
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TRAINYL',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Cargo de Operación',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Tienda: ${orDash(storeName)}',
            style: pw.TextStyle(
              fontSize: 13,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          // ── Resumen de la operación ─────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                kvRow('PLACA', placa, 'CONDUCTOR', conductor),
                pw.Divider(color: _line, height: 1),
                kvRow('TIENDA', storeName, 'ITEMS', '$itemsUnicos'),
                pw.Divider(color: _line, height: 1),
                kvRow('HORA DE REGISTRO', _df.format(registro),
                    'HORA DE TÉRMINO', _df.format(termino)),
                pw.Divider(color: _line, height: 1),
                kvRow('TIEMPO TRANSCURRIDO', elapsedStr,
                    'REGISTRADOS ÚNICOS', '$itemsUnicos'),
                pw.Divider(color: _line, height: 1),
                kvRow('DUPLICADOS', duplicados == 0 ? '-' : '$duplicados',
                    'TOTAL DE LECTURAS', '$total'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Detalle de escaneo ──────────────────────────────────────────
          pw.Text(
            'Detalle de escaneo',
            style: pw.TextStyle(
              fontSize: 13,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Código', 'Hora', 'Estado'],
            data: rows
                .map((r) => [
                      '${r.index}',
                      r.code,
                      _dfHora.format(r.time),
                      r.status,
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(color: _blue),
            cellHeight: 16,
            cellStyle: pw.TextStyle(fontSize: 9, color: _ink),
            oddRowDecoration: pw.BoxDecoration(color: _rowAlt),
            border: pw.TableBorder.all(color: _line, width: 0.5),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(58),
              3: const pw.FixedColumnWidth(70),
            },
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ),
      ),
    );

    return doc.save();
  }
}
