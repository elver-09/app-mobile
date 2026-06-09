import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/pickup_store_model.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/widgets/brand_header.dart';

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
  static const _bright = Color(0xFF2176D2);
  static const _accent = Color(0xFF1A5BB5);
  static const _soft = Color(0xFFEFF4FD);
  static const _bgTint = Color(0xFFEEF3FB);

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
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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

        if (!_collected.any((c) => c.orderNumber == number)) {
          setState(() {
            _collected.insert(0, _Collected(orderNumber: number, fullname: name));
          });
        }
        _snack('Recogido: $number', _accent);
      } else {
        final err = result['error']?.toString() ?? 'No se pudo recoger la orden';
        final code2 = result['code']?.toString();
        _snack(
          err,
          code2 == 'already_collected'
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEF4444),
        );
      }
    } catch (e) {
      _snack('Error: $e', const Color(0xFFEF4444));
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
            prefixIcon: const Icon(Icons.qr_code, color: _accent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              borderSide: const BorderSide(color: _accent, width: 2),
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
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
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
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bgTint,
      body: Column(
        children: [
          // ── Encabezado curvo corporativo ──────────────────────────────────
          BrandHeader(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.getResponsiveSize(14),
                topInset + responsive.getResponsiveSize(12),
                responsive.getResponsiveSize(14),
                responsive.getResponsiveSize(28),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.18),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child:
                            Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.getResponsiveSize(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Escanear recojo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 19,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded,
                                size: 13, color: Colors.white.withOpacity(0.85)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.store.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Cuerpo ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(responsive.getResponsiveSize(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          size: 16, color: _accent),
                      SizedBox(width: responsive.getResponsiveSize(6)),
                      Expanded(
                        child: Text(
                          'Apunta al código del pedido para marcarlo como RECOGIDO',
                          style: TextStyle(
                            fontSize: responsive.getResponsiveFontSize(12.5),
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.getResponsiveSize(12)),
                  // Cámara
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(responsive.borderRadius + 4),
                      border: Border.all(color: _bright, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _bright.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(responsive.borderRadius + 2),
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
                                    color: Colors.white.withOpacity(0.9),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      responsive.borderRadius - 6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _bright.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isProcessing)
                              Container(
                                color: const Color(0xFF0E2C63).withOpacity(0.35),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
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
                          color: _soft,
                          borderRadius:
                              BorderRadius.circular(responsive.borderRadius - 2),
                          child: InkWell(
                            onTap: _showManualDialog,
                            borderRadius: BorderRadius.circular(
                                responsive.borderRadius - 2),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: responsive.getResponsiveSize(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.keyboard,
                                      color: _accent, size: 18),
                                  SizedBox(width: responsive.getResponsiveSize(8)),
                                  Text(
                                    'Ingresar código',
                                    style: TextStyle(
                                      fontSize: responsive.getResponsiveFontSize(12.5),
                                      fontWeight: FontWeight.w700,
                                      color: _accent,
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
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.getResponsiveSize(14),
                      vertical: responsive.getResponsiveSize(12),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(responsive.borderRadius),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_rounded,
                                color: _accent, size: 18),
                            SizedBox(width: responsive.getResponsiveSize(8)),
                            Text(
                              'Pedidos recogidos',
                              style: TextStyle(
                                fontSize: responsive.getResponsiveFontSize(15),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A7AE4), Color(0xFF143C82)],
                            ),
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
                  ),
                  SizedBox(height: responsive.getResponsiveSize(10)),
                  if (_collected.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.getResponsiveSize(22),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.07),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.inventory_2_outlined,
                                  size: responsive.iconSize * 1.6,
                                  color: _accent.withOpacity(0.7)),
                            ),
                            SizedBox(height: responsive.getResponsiveSize(10)),
                            Text(
                              'Aún no has recogido pedidos',
                              style: TextStyle(
                                fontSize: responsive.getResponsiveFontSize(15),
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
        ],
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
          color: const Color(0xFF1A5BB5).withOpacity(0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C80).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF4FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF1A5BB5), size: 18),
          ),
          SizedBox(width: responsive.getResponsiveSize(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.orderNumber,
                  style: TextStyle(
                    fontSize: responsive.getResponsiveFontSize(15),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (item.fullname.isNotEmpty)
                  Text(
                    item.fullname,
                    style: TextStyle(
                      fontSize: responsive.getResponsiveFontSize(12.5),
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1A5BB5).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Recogido',
              style: TextStyle(
                color: Color(0xFF1A5BB5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
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
      color: _on ? const Color(0xFF1A5BB5) : const Color(0xFFEFF4FD),
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
                  color: _on ? Colors.white : const Color(0xFF1A5BB5), size: 18),
              SizedBox(width: responsive.getResponsiveSize(8)),
              Text(
                'Linterna',
                style: TextStyle(
                  fontSize: responsive.getResponsiveFontSize(12.5),
                  fontWeight: FontWeight.w700,
                  color: _on ? Colors.white : const Color(0xFF1A5BB5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
