import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanAssignedOrders extends StatefulWidget {
  final String nombreSede;
  final int ordenesAsignadas;

  const ScanAssignedOrders({
    super.key,
    required this.nombreSede,
    required this.ordenesAsignadas,
  });

  @override
  State<ScanAssignedOrders> createState() => _ScanAssignedOrdersState();
}
class _ScanAssignedOrdersState extends State<ScanAssignedOrders> {
  final MobileScannerController controller = MobileScannerController();
  bool isScannerActive = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escanea tus órdenes de hoy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 1),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sede: ${widget.nombreSede}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Asignadas: ${widget.ordenesAsignadas} Órdenes',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Escaneadas: 0 / ${widget.ordenesAsignadas}',
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Escanea cada etiqueta antes de salir.',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Área de escaneo
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 200,
                    child: isScannerActive
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: MobileScanner(
                              controller: controller,
                              onDetect: (capture) {
                                final List<Barcode> barcodes = capture.barcodes;
                                for (final barcode in barcodes) {
                                  debugPrint('Código escaneado: ${barcode.rawValue}');
                                  // Aquí puedes manejar el código escaneado
                                }
                              },
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              setState(() {
                                isScannerActive = true;
                              });
                            },
                            child: CustomPaint(
                              painter: DashedBorderPainter(
                                color: const Color(0xFF2563EB),
                                strokeWidth: 2,
                                dashWidth: 8,
                                dashSpace: 4,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 60,
                                      color: const Color(0xFF2563EB),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Apunta al código de barras o QR\nde la orden',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Botón escanear
                Center(
                  child: SizedBox(
                    width: 300,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isScannerActive = true;
                        });
                      },
                      icon: const Icon(Icons.crop_free, color: Colors.white),
                      label: const Text(
                        'Escanear siguiente orden',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Ingresar manualmente
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // Lógica para ingresar manualmente
                    },
                    icon: const Icon(
                      Icons.keyboard,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                    label: const Text(
                      'Ingresar código manualmente',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Alerta de órdenes faltantes
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Color(0xFFDC2626),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Faltan órdenes por escanear',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Te faltan 6 órdenes para coincidir con las ${widget.ordenesAsignadas} asignadas a esta sede. Revisa si hay bultos sin etiqueta o códigos dañados.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Últimos escaneos
                const Text(
                  'Últimos escaneos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEscaneoItem('ORD-1023-01', '08:04'),
                const Divider(height: 1),
                _buildEscaneoItem('ORD-1024-02', '08:03'),
                const Divider(height: 1),
                _buildEscaneoItem('ORD-1025-01', '08:02'),
                const SizedBox(height: 24),
                // Ver lista de órdenes asignadas
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // Lógica para ver lista
                    },
                    icon: const Icon(
                      Icons.checklist,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                    label: const Text(
                      'Ver lista de órdenes asignadas',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Botón continuar a rutas
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context, 
                        '/fullScan',
                        arguments: {
                          'nombreSede': widget.nombreSede,
                          'ordenesAsignadas': widget.ordenesAsignadas,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continuar a rutas (faltan órdenes)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildEscaneoItem(String codigo, String hora) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            codigo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            hora,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const radius = 12.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        dashPath.addPath(extractPath, Offset.zero);
        distance = nextDistance + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}