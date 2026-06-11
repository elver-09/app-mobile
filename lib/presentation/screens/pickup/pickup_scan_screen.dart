import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/pickup_store_model.dart';
import 'package:trainyl_2_0/core/pdf/cargo_pdf.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/widgets/brand_header.dart';

/// Escáner de RECOJO en tienda.
/// Cada código escaneado se envía a `scan_pickup`: si la orden está en
/// BORRADOR pasa a RECOGIDO (collett). Permite escanear varios seguidos.
class PickupScanScreen extends StatefulWidget {
  final String token;
  final OdooClient odooClient;
  final PickupStore store;
  final Map<String, dynamic> driver;
  final String placa;

  const PickupScanScreen({
    super.key,
    required this.token,
    required this.odooClient,
    required this.store,
    required this.driver,
    this.placa = '',
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
  final Set<String> _seenCodes = <String>{};
  int _duplicates = 0;
  bool _finished = false;
  bool _loading = true;
  bool _generating = false;
  bool _isProcessing = false;
  String? _lastCode;
  DateTime? _lastAt;
  static const Duration _cooldown = Duration(seconds: 2);

  String get _storageKey => 'pickup_session_${widget.store.id}';

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      autoStart: true,
      formats: const [BarcodeFormat.all],
    );
    _loadSession();
  }

  // ── Persistencia de la sesión (sobrevive salir y volver) ──────────────────
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? [];
        _collected
          ..clear()
          ..addAll(items.map((e) {
            final m = e as Map<String, dynamic>;
            return _Collected(
              code: m['code']?.toString() ?? '',
              orderNumber: m['orderNumber']?.toString() ?? '',
              fullname: m['fullname']?.toString() ?? '',
              time: DateTime.fromMillisecondsSinceEpoch(
                  (m['time'] as num?)?.toInt() ?? 0),
            );
          }));
        _seenCodes
          ..clear()
          ..addAll(_collected.map((c) => c.code.toUpperCase()));
        _duplicates = (data['duplicates'] as num?)?.toInt() ?? 0;
        _finished = data['finished'] == true;
      }
    } catch (_) {
      // Si algo falla, simplemente arranca una sesión nueva
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'items': _collected
            .map((c) => {
                  'code': c.code,
                  'orderNumber': c.orderNumber,
                  'fullname': c.fullname,
                  'time': c.time.millisecondsSinceEpoch,
                })
            .toList(),
        'duplicates': _duplicates,
        'finished': _finished,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  Future<void> _confirmFinish() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Finalizar escaneo'),
        content: Text(
          'Vas a cerrar el escaneo de ${widget.store.name} con '
          '${_collected.length} pedido(s). Después podrás imprimir el cargo, '
          'pero no agregar más pedidos a esta sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _finished = true);
      await _saveSession();
    }
  }

  Future<void> _startNew() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Iniciar nuevo escaneo'),
        content: const Text(
          'Esto borrará el cargo actual de esta tienda y empezará de cero. '
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _collected.clear();
        _seenCodes.clear();
        _duplicates = 0;
        _finished = false;
      });
      await _clearSession();
    }
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

    // Duplicado dentro de la misma sesión (sin distinguir may/min)
    if (_seenCodes.contains(code.toUpperCase())) {
      setState(() => _duplicates++);
      _saveSession();
      _snack('Código duplicado: $code', const Color(0xFFF59E0B));
      return;
    }

    // Validación de formato (solo si el cliente lo exige, ej. Ripley).
    // Evita que el escáner sensible procese códigos basura.
    if (widget.store.scanValidate) {
      final prefix = widget.store.scanPrefix.trim();
      final len = widget.store.scanLength;
      if (prefix.isNotEmpty && !code.startsWith(prefix)) {
        _snack('Código inválido: debe empezar con $prefix',
            const Color(0xFFEF4444));
        return;
      }
      if (len > 0 && code.length != len) {
        _snack('Código inválido: debe tener $len caracteres',
            const Color(0xFFEF4444));
        return;
      }
    }

    setState(() => _isProcessing = true);
    try {
      final result = await widget.odooClient.scanPickupOrder(
        token: widget.token,
        orderCode: code,
        storeId: widget.store.id,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final order = (result['order'] as Map?) ?? {};
        final number = order['order_number']?.toString() ?? code;
        final name = order['fullname']?.toString() ?? '';

        _seenCodes.add(code.toUpperCase());
        setState(() {
          _collected.insert(
            0,
            _Collected(
              code: code,
              orderNumber: number,
              fullname: name,
              time: DateTime.now(),
            ),
          );
        });
        _saveSession();
        final created = result['created'] == true;
        _snack(
          created ? 'Creado y recogido: $number' : 'Recogido: $number',
          _accent,
        );
      } else {
        final err = result['error']?.toString() ?? 'No se pudo recoger la orden';
        final code2 = result['code']?.toString();
        if (code2 == 'already_collected') {
          setState(() => _duplicates++);
          _saveSession();
          _snack(err, const Color(0xFFF59E0B));
        } else {
          _snack(err, const Color(0xFFEF4444));
        }
      }
    } catch (e) {
      _snack('Error: $e', const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Genera el "Cargo de Operación" en PDF con lo escaneado en esta tienda
  /// y abre el diálogo para imprimir o guardar.
  Future<void> _generateCargo() async {
    if (_collected.isEmpty || _generating) return;
    setState(() => _generating = true);
    try {
      // Orden cronológico (1..N) para el detalle
      final ordered = [..._collected]..sort((a, b) => a.time.compareTo(b.time));

      // Registro = primer escaneo · Término = último escaneo
      final registro = ordered.first.time;
      final termino = ordered.last.time;

      final rows = <CargoScanRow>[];
      for (var i = 0; i < ordered.length; i++) {
        rows.add(CargoScanRow(
          index: i + 1,
          code: ordered[i].code,
          time: ordered[i].time,
        ));
      }

      final conductor = (widget.driver['name'] as String?)?.trim() ?? '';
      var placa = widget.placa.trim();
      if (placa.isEmpty) {
        placa = (widget.driver['placa'] as String?)?.trim() ?? '';
      }

      final bytes = await CargoPdf.build(
        storeName: widget.store.fullName,
        conductor: conductor,
        placa: placa,
        registro: registro,
        termino: termino,
        itemsUnicos: _collected.length,
        duplicados: _duplicates,
        rows: rows,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: CargoPdf.fileName(widget.store.fullName, termino),
      );
    } catch (e) {
      if (mounted) _snack('No se pudo generar el cargo: $e', const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _generating = false);
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: EdgeInsets.all(responsive.getResponsiveSize(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_finished) ...[
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
                  ],
                  if (_finished) ...[
                    _FinishedBanner(count: _collected.length),
                    SizedBox(height: responsive.getResponsiveSize(16)),
                  ],
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
                  if (!_finished && _collected.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmFinish,
                        icon: const Icon(Icons.flag_rounded, color: Colors.white),
                        label: const Text(
                          'Finalizar escaneo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF143C82),
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.getResponsiveSize(14),
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(responsive.borderRadius),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(14)),
                  ],
                  if (_finished) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generating ? null : _generateCargo,
                        icon: _generating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf_rounded,
                                color: Colors.white),
                        label: Text(
                          _generating
                              ? 'Generando...'
                              : 'Imprimir / Guardar cargo (PDF)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.getResponsiveSize(14),
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(responsive.borderRadius),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(6)),
                    TextButton.icon(
                      onPressed: _startNew,
                      icon: const Icon(Icons.refresh_rounded,
                          size: 18, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Iniciar nuevo escaneo',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(10)),
                  ],
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
  final String code;
  final String orderNumber;
  final String fullname;
  final DateTime time;
  _Collected({
    required this.code,
    required this.orderNumber,
    required this.fullname,
    required this.time,
  });
}

class _FinishedBanner extends StatelessWidget {
  final int count;
  const _FinishedBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A7AE4), Color(0xFF143C82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsive.borderRadius + 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF143C82).withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 26),
          ),
          SizedBox(width: responsive.getResponsiveSize(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escaneo finalizado',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.getResponsiveFontSize(16),
                  ),
                ),
                SizedBox(height: responsive.getResponsiveSize(2)),
                Text(
                  '$count pedido(s) listos para el cargo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: responsive.getResponsiveFontSize(12.5),
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
