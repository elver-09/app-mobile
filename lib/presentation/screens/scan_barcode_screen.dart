import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DottedBorder extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DottedBorder({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5;
    const dashSpace = 5;
    double startX = 0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    // Top border
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }

    // Right border
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Bottom border
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX - dashWidth, size.height),
        paint,
      );
      startX -= dashWidth + dashSpace;
    }

    // Left border
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DottedBorder oldDelegate) => false;
}

class ScanBarcodeScreen extends StatefulWidget {
  final String routeName;
  final String fleetType;
  final String fleetLicense;
  final List<OrderItem> orders;
  final OdooClient? odooClient;
  final String? token;

  const ScanBarcodeScreen({
    super.key,
    required this.routeName,
    required this.fleetType,
    required this.fleetLicense,
    required this.orders,
    this.odooClient,
    this.token,
  });

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  late MobileScannerController cameraController;
  OrderItem? _scannedOrder;
  final TextEditingController _codeController = TextEditingController();
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      autoStart: true,
      formats: const [BarcodeFormat.all],
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _searchOrderByCode(String code) {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Por favor ingresa un código'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      final order = widget.orders.firstWhere(
        (o) => o.orderNumber.toLowerCase() == code.toLowerCase(),
      );

      setState(() {
        _scannedOrder = order;
      });

      print('✅ Orden encontrada: ${order.orderNumber}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Orden encontrada: ${order.orderNumber}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      print('❌ Orden no encontrada: $code');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ No se encontró la orden con código: $code'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _confirmScanOrder() async {
    if (_scannedOrder == null) return;
    
    print('🔵 ===== INICIO CONFIRMACIÓN DE ESCANEO =====');
    print('🔵 Orden ID: ${_scannedOrder!.id}');
    print('🔵 Orden número: ${_scannedOrder!.orderNumber}');
    print('🔵 Estado actual en app: ${_scannedOrder!.planningStatus}');
    
    setState(() {
      _isConfirming = true;
    });

    try {
      // Obtener token y cliente Odoo
      final prefs = await SharedPreferences.getInstance();
      final token = widget.token ?? prefs.getString('driver_token') ?? '';
      final odooClient = widget.odooClient ?? OdooClient(
        baseUrl: prefs.getString('odoo_url') ?? '',
        db: prefs.getString('odoo_db') ?? '',
      );

      print('🔵 Token obtenido: ${token.isNotEmpty ? "✅ OK" : "❌ VACÍO"}');

      if (token.isEmpty) {
        print('❌ ERROR: Token vacío, no se puede continuar');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error: No se encontró token de autenticación'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      print('🔵 Llamando a endpoint scanConfirmOrder...');
      // Llamar al endpoint de confirmación
      final result = await odooClient.scanConfirmOrder(
        token: token,
        orderId: _scannedOrder!.id,
      );

      print('🔵 ===== RESPUESTA DEL SERVIDOR =====');
      print('🔵 Success: ${result['success']}');
      print('🔵 Message: ${result['message']}');
      print('🔵 Nuevo estado: ${result['new_status']}');
      print('🔵 Error (si hay): ${result['error']}');
      print('🔵 =====================================');

      if (!mounted) return;

      if (result['success'] == true) {
        print('✅ ÉXITO: Orden confirmada en Odoo');
        print('✅ La orden ${_scannedOrder!.orderNumber} cambió a estado: ${result['new_status']}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result["message"] ?? "Orden confirmada y en transporte"}'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );

        // Limpiar orden escaneada para permitir escanear otra
        setState(() {
          _scannedOrder = null;
        });

        print('🔵 Regresando a pantalla anterior para refrescar...');
        // Regresar a la pantalla anterior para refrescar la lista
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
          print('✅ Navegación completada');
        }
      } else {
        print('❌ ERROR: La respuesta del servidor indica fallo');
        print('❌ Motivo: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result["error"] ?? "Error al confirmar orden"}'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ EXCEPCIÓN EN _confirmScanOrder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      print('🔵 ===== FIN CONFIRMACIÓN DE ESCANEO =====');
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  void _showManualCodeDialog() {
    _codeController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Ingresar código manualmente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa el número de orden para buscarla',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Código de orden',
                  hintText: 'Ej: PRUEBA 003',
                  prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF2563EB)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  Navigator.pop(context);
                  _searchOrderByCode(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _searchOrderByCode(_codeController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Buscar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Escanear códigos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Apunta al código de barras para marcar la\norden como "En transporte"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hoy • ${widget.routeName}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'Vehículo',
                      style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Estado de ruta',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA726),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Por validar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${widget.fleetType} • ${widget.fleetLicense}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Escaneo en curso',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Alinea el código de barras dentro del recuadro\npara registrar la orden.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomPaint(
                  painter: DottedBorder(
                    color: const Color(0xFFCBD5E1),
                    strokeWidth: 2,
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFF8FAFC),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: MobileScanner(
                        controller: cameraController,
                        onDetect: (capture) {
                          for (final barcode in capture.barcodes) {
                            final code = barcode.rawValue;
                            if (code != null && code.isNotEmpty) {
                              print('📱 Código detectado: $code');
                              _searchOrderByCode(code);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FlashlightButton(
                        label: 'Linterna',
                        controller: cameraController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.keyboard,
                        label: 'Ingresar\ncódigo',
                        onTap: _showManualCodeDialog,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_scannedOrder != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Orden encontrada',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Lista para "En transporte"',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scannedOrder!.fullname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _scannedOrder!.orderNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Producto: ${_scannedOrder!.product ?? 'N/A'} · Zona ${_scannedOrder!.district}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _scannedOrder!.address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _scannedOrder = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isConfirming ? null : _confirmScanOrder,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _isConfirming ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: _isConfirming
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Confirmar escaneo',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Al confirmar, la orden cambiará a estado "En transporte" dentro de tu ruta.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FlashlightButton extends StatefulWidget {
  final String label;
  final MobileScannerController controller;

  const FlashlightButton({required this.label, required this.controller});

  @override
  State<FlashlightButton> createState() => _FlashlightButtonState();
}

class _FlashlightButtonState extends State<FlashlightButton> {
  bool _isFlashlightOn = false;
  static const platform = MethodChannel('com.trainyl/flashlight');

  Future<void> _toggleFlashlight() async {
    try {
      if (_isFlashlightOn) {
        print('🔦 Apagando linterna...');
        await platform.invokeMethod('disableFlashlight');
        print('✅ Linterna apagada exitosamente');
      } else {
        print('🔦 Encendiendo linterna...');
        await platform.invokeMethod('enableFlashlight');
        print('✅ Linterna encendida exitosamente');
      }
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
        print('📊 Estado de linterna: $_isFlashlightOn');
      });
    } on PlatformException catch (e) {
      print('❌ Error al controlar la linterna: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al controlar la linterna: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _isFlashlightOn
          ? const Color(0xFF2563EB)
          : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _toggleFlashlight,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flash_on,
                color: _isFlashlightOn ? Colors.white : const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _isFlashlightOn
                      ? Colors.white
                      : const Color(0xFF2563EB),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isFlashlightOn) {
      platform.invokeMethod('disableFlashlight');
    }
    super.dispose();
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
