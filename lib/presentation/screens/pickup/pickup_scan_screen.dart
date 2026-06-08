import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/pickup_store_model.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';

/// Escáner de RECOJO en tienda.
/// Cada código escaneado se envía a `scan_pickup`: si la orden está en
/// BORRADOR pasa a RECOGIDO (collett). Permite escanear varios seguidos.
class PickupScanScreen extends StatefulWidget {
  final String token;
  final OdooClient odooClient;
  final PickupStore store;

  const PickupScanScreen({
    super.key,
    required this.token,
    required this.odooClient,
    required this.store,
  });

  @override
  State<PickupScanScreen> createState() => _PickupScanScreenState();
}

class _PickupScanScreenState extends State<PickupScanScreen> {
  late MobileScannerController cameraController;
  final TextEditingController _codeController = TextEditingController();

  final List<_Collected> _collected = [];
  bool _isProcessing = false;
  String? _lastCode;
  DateTime? _lastAt;
  static const Duration _cooldown = Duration(seconds: 2);

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

  bool _shouldIgnore(String code) {
    final now = DateTime.now();
    final normalized = code.trim();
    if (normalized.isEmpty) return true;
    final same = _lastCode == normalized;
    final inCooldown = _lastAt != null && now.difference(_lastAt!) < _cooldown;
    if (same && inCooldown) return true;
    _lastCode = normalized;
    _lastAt = now;
    return false;
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _processCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final result = await widget.odooClient.scanPickupOrder(
        token: widget.token,
        orderCode: code,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final order = (result['order'] as Map?) ?? {};
        final number = order['order_number']?.toString() ?? code;
        final name = order['fullname']?.toString() ?? '';

        // Evitar duplicados en la lista visual
        if (!_collected.any((c) => c.orderNumber == number)) {
          setState(() {
            _collected.insert(0, _Collected(orderNumber: number, fullname: name));
          });
        }
        _snack('✅ Recogido: $number', const Color(0xFF10B981));
      } else {
        final err = result['error']?.toString() ?? 'No se pudo recoger la orden';
        final code2 = result['code']?.toString();
        _snack(
          '⚠️ $err',
          code2 == 'already_collected'
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEF4444),
        );
      }
    } catch (e) {
      _snack('❌ Error: $e', const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showManualDialog() {
    final responsive = context.responsive;
    _codeController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        title: const Text('Ingresar código manualmente'),
        content: TextField(
          controller: _codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Código de orden',
            hintText: 'Ej: 0600050704700',
            prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF0F766E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
            ),
          ),
          onSubmitted: (v) {
            Navigator.pop(context);
            _processCode(v);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
            ),
            onPressed: () {
              Navigator.pop(context);
              _processCode(_codeController.text);
            },
            child: const Text('Buscar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escanear recojo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                fontSize: 16,
              ),
            ),
            Text(
              widget.store.name,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsive.getResponsiveSize(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apunta al código del pedido para marcarlo como RECOGIDO',
                style: TextStyle(
                  fontSize: responsive.bodySmallFontSize,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: responsive.getResponsiveSize(10)),
              // Cámara
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                  border: Border.all(color: const Color(0xFF0EA5A4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5A4).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(responsive.borderRadius - 2),
                  child: SizedBox(
                    height: responsive.getResponsiveSize(230),
                    width: double.infinity,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: cameraController,
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              final code = barcode.rawValue;
                              if (code != null && code.isNotEmpty) {
                                if (_shouldIgnore(code)) continue;
                                _processCode(code);
                                break;
                              }
                            }
                          },
                        ),
                        Center(
                          child: Container(
                            width: responsive.getResponsiveSize(220),
                            height: responsive.getResponsiveSize(110),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.6),
                                width: 2,
                              ),
                              borderRadius:
                                  BorderRadius.circular(responsive.borderRadius - 6),
                            ),
                          ),
                        ),
                        if (_isProcessing)
                          Container(
                            color: Colors.black.withOpacity(0.25),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.getResponsiveSize(10)),
              // Acciones
              Row(
                children: [
                  Expanded(
                    child: _FlashlightButton(controller: cameraController),
                  ),
                  SizedBox(width: responsive.getResponsiveSize(8)),
                  Expanded(
                    child: Material(
                      color: const Color(0xFFF0FDFA),
                      borderRadius:
                          BorderRadius.circular(responsive.borderRadius - 2),
                      child: InkWell(
                        onTap: _showManualDialog,
                        borderRadius:
                            BorderRadius.circular(responsive.borderRadius - 2),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.getResponsiveSize(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.keyboard,
                                  color: Color(0xFF0F766E), size: 18),
                              SizedBox(width: responsive.getResponsiveSize(8)),
                              Text(
                                'Ingresar código',
                                style: TextStyle(
                                  fontSize: responsive.bodySmallFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F766E),
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
              SizedBox(height: responsive.getResponsiveSize(16)),
              // Contador
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recogidos',
                    style: TextStyle(
                      fontSize: responsive.headingMediumFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.getResponsiveSize(12),
                      vertical: responsive.getResponsiveSize(4),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_collected.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.getResponsiveSize(8)),
              if (_collected.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.getResponsiveSize(24),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: responsive.iconSize * 1.8,
                            color: const Color(0xFFCBD5E1)),
                        SizedBox(height: responsive.getResponsiveSize(8)),
                        Text(
                          'Aún no has recogido pedidos',
                          style: TextStyle(
                            fontSize: responsive.bodyMediumFontSize,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._collected.map((c) => _CollectedTile(item: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Collected {
  final String orderNumber;
  final String fullname;
  _Collected({required this.orderNumber, required this.fullname});
}

class _CollectedTile extends StatelessWidget {
  final _Collected item;
  const _CollectedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      margin: EdgeInsets.only(bottom: responsive.getResponsiveSize(8)),
      padding: EdgeInsets.all(responsive.getResponsiveSize(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981)),
          SizedBox(width: responsive.getResponsiveSize(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.orderNumber,
                  style: TextStyle(
                    fontSize: responsive.bodyMediumFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (item.fullname.isNotEmpty)
                  Text(
                    item.fullname,
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
    );
  }
}

class _FlashlightButton extends StatefulWidget {
  final MobileScannerController controller;
  const _FlashlightButton({required this.controller});

  @override
  State<_FlashlightButton> createState() => _FlashlightButtonState();
}

class _FlashlightButtonState extends State<_FlashlightButton> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Material(
      color: _on ? const Color(0xFF0EA5A4) : const Color(0xFFF0FDFA),
      borderRadius: BorderRadius.circular(responsive.borderRadius - 2),
      child: InkWell(
        onTap: () async {
          try {
            await widget.controller.toggleTorch();
            setState(() => _on = !_on);
          } catch (_) {}
        },
        borderRadius: BorderRadius.circular(responsive.borderRadius - 2),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.getResponsiveSize(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on,
                  color: _on ? Colors.white : const Color(0xFF0F766E), size: 18),
              SizedBox(width: responsive.getResponsiveSize(8)),
              Text(
                'Linterna',
                style: TextStyle(
                  fontSize: responsive.bodySmallFontSize,
                  fontWeight: FontWeight.w700,
                  color: _on ? Colors.white : const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
