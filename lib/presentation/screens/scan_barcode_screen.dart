import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
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
      print('❌ Orden no encontrada localmente: $code');
      // Buscar globalmente en el servidor
      _searchOrderGlobally(code);
    }
  }

  Future<void> _searchOrderGlobally(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = widget.token ?? prefs.getString('driver_token') ?? '';
      
      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Token no disponible'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final odooClient = widget.odooClient ?? OdooClient(
        baseUrl: 'https://trainyl.digilab.pe',
        db: 'trainyl-prd',
      );

      print('🔵 Buscando orden globalmente: $code');
      final result = await odooClient.searchOrderGlobal(
        token: token,
        orderCode: code,
      );

      if (!mounted) return;

      if (result['success'] == true && result['found'] == true) {
        if (result['belongs_to_another_route'] == true) {
          final routeInfo = result['route_info'];
          final orderInfo = result['order'];
          
          // Mostrar alerta con información de la ruta correcta
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFFF9FAFB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ORDEN EN OTRA RUTA',
                        style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text(
                        'Esta orden pertenece a:',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF111827), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              context,
                              Icons.directions_car,
                              'RUTA:',
                              routeInfo['route_name'] ?? 'N/A',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              Icons.person_pin,
                              'CONDUCTOR:',
                              routeInfo['driver_name'] ?? 'N/A',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              context,
                              Icons.local_shipping,
                              'ORDEN:',
                              orderInfo['order_number'] ?? 'N/A',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CERRAR', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                  ),
                ],
              );
            },
          );

          print('⚠️ Orden pertenece a otra ruta: ${routeInfo['route_name']}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Esta orden no está asignada a ninguna ruta'),
              backgroundColor: Color(0xF59E0B),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? '❌ Orden no encontrada'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      print('❌ Error en búsqueda global: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al buscar la orden'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
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
    final responsive = context.responsive;
    _codeController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
          ),
          title: Text(
            'Ingresar código manualmente',
            style: TextStyle(
              fontSize: responsive.headingSmallFontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa el número de orden para buscarla',
                style: TextStyle(
                  fontSize: responsive.bodySmallFontSize,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: responsive.getResponsiveSize(16)),
              TextField(
                controller: _codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Código de orden',
                  hintText: 'Ej: 0600050704700',
                  prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF2563EB)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
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
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: responsive.bodyMediumFontSize,
                  color: const Color(0xFF64748B),
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
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.getResponsiveSize(24),
                  vertical: responsive.getResponsiveSize(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius - 2),
                ),
              ),
              child: Text(
                'Buscar',
                style: TextStyle(
                  fontSize: responsive.bodyMediumFontSize,
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
    final responsive = context.responsive;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header atractivo
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(responsive.getResponsiveSize(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(responsive.getResponsiveSize(8)),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(responsive.borderRadius),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: const Color(0xFF0F172A),
                              size: responsive.iconSize,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        SizedBox(width: responsive.getResponsiveSize(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Escanear códigos',
                                style: TextStyle(
                                  fontSize: responsive.headingLargeFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: responsive.getResponsiveSize(4)),
                              Text(
                                'Apunta al código para marcar "En transporte"',
                                style: TextStyle(
                                  fontSize: responsive.bodySmallFontSize,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Información de ruta y vehículo
              Padding(
                padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hoy • ${widget.routeName}',
                              style: TextStyle(
                                fontSize: responsive.bodyMediumFontSize,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: responsive.getResponsiveSize(2)),
                            Row(
                              children: [
                                Text(
                                  'Estado de ruta',
                                  style: TextStyle(
                                    fontSize: responsive.bodySmallFontSize,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(width: responsive.getResponsiveSize(8)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsive.getResponsiveSize(12),
                                    vertical: responsive.getResponsiveSize(4),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFFA726),
                                        const Color(0xFFFF9800),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFA726).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Por validar',
                                    style: TextStyle(
                                      fontSize: responsive.bodySmallFontSize * 0.8,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Vehículo',
                              style: TextStyle(
                                fontSize: responsive.bodySmallFontSize,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: responsive.getResponsiveSize(2)),
                            Text(
                              '${widget.fleetType} • ${widget.fleetLicense}',
                              style: TextStyle(
                                fontSize: responsive.bodyMediumFontSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.getResponsiveSize(12)),
                    // Sección de escaneo
                    Container(
                      padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(responsive.borderRadius),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Escaneo en curso',
                                    style: TextStyle(
                                      fontSize: responsive.headingMediumFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: responsive.getResponsiveSize(4)),
                                  Text(
                                    'Alinea el código dentro del recuadro',
                                    style: TextStyle(
                                      fontSize: responsive.bodySmallFontSize,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.all(responsive.getResponsiveSize(10)),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF3B82F6).withOpacity(0.1),
                                      const Color(0xFF2563EB).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(
                                  Icons.fullscreen,
                                  color: const Color(0xFF3B82F6),
                                  size: responsive.iconSize,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.getResponsiveSize(16)),
                          // Scanner con marco atractivo
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(responsive.borderRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: DottedBorder(
                                color: const Color(0xFF3B82F6),
                                strokeWidth: 2.5,
                              ),
                              child: Container(
                                height: responsive.getResponsiveSize(220),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(responsive.borderRadius - 4),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF0F9FF),
                                      const Color(0xFFF8FAFC),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(responsive.borderRadius - 6),
                                  child: Stack(
                                    children: [
                                      MobileScanner(
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
                                      // Overlay con líneas de escaneo
                                      Center(
                                        child: Container(
                                          width: responsive.getResponsiveSize(220),
                                          height: responsive.getResponsiveSize(120),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFF10B981).withOpacity(0.5),
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(responsive.borderRadius - 6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(8)),
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: FlashlightButton(
                            label: 'Linterna',
                            controller: cameraController,
                          ),
                        ),
                        SizedBox(width: responsive.getResponsiveSize(12)),
                        Expanded(
                          child: _ActionChip(
                            icon: Icons.keyboard,
                            label: 'Ingresar\ncódigo',
                            onTap: _showManualCodeDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_scannedOrder != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.getResponsiveSize(16),
                    vertical: responsive.getResponsiveSize(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado con badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Orden encontrada',
                            style: TextStyle(
                              fontSize: responsive.headingMediumFontSize,
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.getResponsiveSize(12),
                              vertical: responsive.getResponsiveSize(6),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: responsive.iconSize * 0.7,
                                ),
                                SizedBox(width: responsive.getResponsiveSize(4)),
                                Text(
                                  'Lista para confirmar',
                                  style: TextStyle(
                                    fontSize: responsive.bodySmallFontSize * 0.85,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.getResponsiveSize(12)),
                      // Tarjeta de orden
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(responsive.borderRadius),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Encabezado de orden
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _scannedOrder!.fullname,
                                        style: TextStyle(
                                          fontSize: responsive.headingSmallFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: responsive.getResponsiveSize(4)),
                                      Text(
                                        _scannedOrder!.orderNumber,
                                        style: TextStyle(
                                          fontSize: responsive.bodyMediumFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(responsive.getResponsiveSize(8)),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(responsive.borderRadius - 4),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping,
                                    color: const Color(0xFF10B981),
                                    size: responsive.iconSize,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: responsive.getResponsiveSize(12)),
                            // Detalles
                            Divider(
                              color: const Color(0xFFE2E8F0),
                              thickness: 1,
                              height: responsive.getResponsiveSize(20),
                            ),
                            Text(
                              'Detalles del envío',
                              style: TextStyle(
                                fontSize: responsive.bodyMediumFontSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: responsive.getResponsiveSize(8)),
                            _buildDetailRow(
                              context,
                              Icons.inventory_2,
                              'Producto',
                              _scannedOrder!.product ?? 'N/A',
                            ),
                            SizedBox(height: responsive.getResponsiveSize(6)),
                            _buildDetailRow(
                              context,
                              Icons.location_on,
                              'Zona',
                              _scannedOrder!.district,
                            ),
                            SizedBox(height: responsive.getResponsiveSize(6)),
                            _buildDetailRow(
                              context,
                              Icons.attach_money,
                              'Dirección',
                              _scannedOrder!.address,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: responsive.getResponsiveSize(16)),
                      // Botón de confirmación
                      SizedBox(
                        width: double.infinity,
                        height: responsive.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _isConfirming ? null : _confirmScanOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
                            elevation: 4,
                            shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(responsive.borderRadius),
                            ),
                          ),
                          child: _isConfirming
                              ? SizedBox(
                                  height: responsive.buttonHeight * 0.5,
                                  width: responsive.buttonHeight * 0.5,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: responsive.iconSize,
                                    ),
                                    SizedBox(width: responsive.getResponsiveSize(8)),
                                    Text(
                                      'Confirmar y marcar en transporte',
                                      style: TextStyle(
                                        fontSize: responsive.headingSmallFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: responsive.getResponsiveSize(12)),
                      // Botón secundario
                      SizedBox(
                        width: double.infinity,
                        height: responsive.buttonHeight * 0.9,
                        child: OutlinedButton(
                          onPressed: _isConfirming
                              ? null
                              : () {
                                  setState(() {
                                    _scannedOrder = null;
                                  });
                                  _codeController.clear();
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(responsive.borderRadius),
                            ),
                          ),
                          child: Text(
                            'Cancelar y escanear otra',
                            style: TextStyle(
                              fontSize: responsive.bodyMediumFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(height: responsive.getResponsiveSize(20)),
                        Icon(
                          Icons.camera_alt_outlined,
                          size: responsive.iconSize * 2,
                          color: const Color(0xFFCBD5E1),
                        ),
                        SizedBox(height: responsive.getResponsiveSize(16)),
                        Text(
                          'Escanea una orden',
                          style: TextStyle(
                            fontSize: responsive.bodyMediumFontSize,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para mostrar detalles en filas
  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final responsive = context.responsive;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: responsive.iconSize * 0.8,
              color: const Color(0xFF64748B),
            ),
            SizedBox(width: responsive.getResponsiveSize(8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.bodySmallFontSize,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(width: responsive.getResponsiveSize(12)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: responsive.bodyMediumFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
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

  Future<void> _toggleFlashlight() async {
    try {
      await widget.controller.toggleTorch();
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
    } catch (e) {
      print('❌ Error al controlar la linterna: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al controlar la linterna: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Material(
      color: _isFlashlightOn
          ? const Color(0xFF3B82F6)
          : const Color(0xFFF0F9FF),
      borderRadius: BorderRadius.circular(responsive.borderRadius - 2),
      child: InkWell(
        onTap: _toggleFlashlight,
        borderRadius: BorderRadius.circular(responsive.borderRadius - 2),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.getResponsiveSize(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flash_on,
                color: _isFlashlightOn ? Colors.white : const Color(0xFF3B82F6),
                size: responsive.iconSize * 0.75,
              ),
              SizedBox(width: responsive.getResponsiveSize(8)),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: responsive.bodySmallFontSize,
                  fontWeight: FontWeight.w700,
                  color: _isFlashlightOn
                      ? Colors.white
                      : const Color(0xFF3B82F6),
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
      widget.controller.toggleTorch();
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
    final responsive = context.responsive;
    
    return Material(
      color: const Color(0xFFF0FDF4),
      borderRadius: BorderRadius.circular(responsive.borderRadius - 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.borderRadius - 2),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.getResponsiveSize(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF059669), size: responsive.iconSize * 0.75),
              SizedBox(width: responsive.getResponsiveSize(8)),
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.bodySmallFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
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
