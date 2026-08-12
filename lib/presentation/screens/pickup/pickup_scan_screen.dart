import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/pickup_store_model.dart';
import 'package:trainyl_2_0/core/offline/pickup_queue_db.dart';
import 'package:trainyl_2_0/core/offline/connectivity_service.dart';
import 'package:trainyl_2_0/core/pdf/cargo_pdf.dart';
import 'package:trainyl_2_0/core/pdf/cargo_pdf_storage.dart';
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
  String? _cargoPdfPath;
  String? _cargoPdfName;
  bool _cargoInPublicDownloads = false;
  String? _lastCode;
  DateTime? _lastAt;
  static const Duration _cooldown = Duration(seconds: 2);

  // ── Offline-first ──
  bool _online = true;
  bool _syncing = false;
  int _pendingCount = 0;
  StreamSubscription<bool>? _connSub;
  final ConnectivityService _conn = ConnectivityService();
  final Uuid _uuidGen = const Uuid();

  String get _storageKey => 'pickup_session_${widget.store.id}';

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      autoStart: true,
      formats: const [BarcodeFormat.all],
    );
    _loadSession();

    // Estado de conexión inicial + escucha de cambios (recupera señal -> sync)
    _conn.isOnline().then((v) {
      if (mounted) setState(() => _online = v);
      if (v) _trySync();
    });
    _connSub = _conn.onStatusChange.listen((online) {
      if (mounted) setState(() => _online = online);
      if (online) _trySync();
    });
  }

  // ── Persistencia: la cola local (sqflite) es la fuente de verdad ──────────
  Future<void> _loadSession() async {
    try {
      final rows = await PickupQueueDb.instance.itemsForStore(widget.store.id);
      _collected
        ..clear()
        ..addAll(rows.map((s) => _Collected(
              uuid: s.uuid,
              code: s.code,
              orderNumber: s.orderNumber.isNotEmpty ? s.orderNumber : s.code,
              fullname: s.fullname,
              time: s.scannedAt,
              status: s.status,
              created: s.created,
              errorMsg: s.errorMsg,
            )));
      _seenCodes
        ..clear()
        ..addAll(_collected.map((c) => c.code.toUpperCase()));

      // dups / finished se guardan como metadato ligero en prefs
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _duplicates = (data['duplicates'] as num?)?.toInt() ?? 0;
        _finished = data['finished'] == true;
        _cargoPdfPath = (data['cargo_pdf_path'] as String?)?.trim();
        _cargoPdfName = (data['cargo_pdf_name'] as String?)?.trim();
        _cargoInPublicDownloads = data['cargo_pdf_public'] == true;
      }
      await _refreshPendingCount();
    } catch (_) {
      // Si algo falla, arranca una sesión nueva
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'duplicates': _duplicates,
        'finished': _finished,
        'cargo_pdf_path': _cargoPdfPath,
        'cargo_pdf_name': _cargoPdfName,
        'cargo_pdf_public': _cargoInPublicDownloads,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    try {
      await PickupQueueDb.instance.clearStore(widget.store.id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      if (mounted) setState(() => _pendingCount = 0);
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
          '${_collected.length} pedido(s). El cargo PDF se guardará '
          'automáticamente en el dispositivo. Después podrás abrirlo o '
          'imprimirlo cuando lo necesites, pero no agregar más pedidos a esta sesión.',
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
      await _saveCargoPdf(showFeedback: true);
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
        _cargoPdfPath = null;
        _cargoPdfName = null;
        _cargoInPublicDownloads = false;
      });
      await _clearSession();
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
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

  // ── Multibulto ───────────────────────────────────────────────────────────
  Future<bool?> _askMultibulto(String code) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.inventory_2_rounded, color: Color(0xFF2A7AE4)),
            SizedBox(width: 8),
            Expanded(child: Text('Código ya escaneado')),
          ],
        ),
        content: Text(
          'El código "$code" ya fue escaneado en esta sesión.\n\n'
          '¿Es multibulto? (varios paquetes para la misma orden)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, es duplicado'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_box_rounded, size: 18, color: Colors.white),
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Sí, multibulto', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _registerMultibulto(String code) async {
    // Encontrar la entrada original de este código
    final idx = _collected.indexWhere(
        (c) => c.code.toUpperCase() == code.toUpperCase());
    if (idx < 0) return;
    final original = _collected[idx];

    // Incrementar el contador (de 0→2, luego +1 cada vez)
    final newCount = (original.multipackCount < 2) ? 2 : original.multipackCount + 1;

    setState(() {
      original.multipackCount = newCount;
    });

    _snack('Multibulto: $code ($newCount bultos)', _accent);

    // Registrar en el backend (si hay conexión)
    if (_online) {
      try {
        await widget.odooClient.registerPickupMultipack(
          token: widget.token,
          orderCode: code,
          packageCount: newCount,
        );
      } catch (_) {
        // Se registrará al sincronizar con el batch
      }
    }
  }

  Future<void> _processCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _isProcessing) return;

    // ── Duplicado: preguntar si es multibulto ──────────────────────────────
    if (_seenCodes.contains(code.toUpperCase())) {
      final isMulti = await _askMultibulto(code);
      if (isMulti == true) {
        await _registerMultibulto(code);
      } else {
        setState(() => _duplicates++);
        _saveSession();
        _snack('Código duplicado: $code', const Color(0xFFF59E0B));
      }
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
      // 1) Se guarda SIEMPRE en la cola local (funciona sin señal).
      final scan = PickupScan(
        uuid: _uuidGen.v4(),
        storeId: widget.store.id,
        code: code,
        scannedAt: DateTime.now(),
      );
      await PickupQueueDb.instance.insert(scan);

      _seenCodes.add(code.toUpperCase());
      setState(() {
        _collected.insert(
          0,
          _Collected(
            uuid: scan.uuid,
            code: code,
            orderNumber: code,
            fullname: '',
            time: scan.scannedAt,
            status: 'pending',
          ),
        );
      });
      _snack('Escaneado: $code', _accent);
    } catch (e) {
      _snack('Error guardando escaneo: $e', const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    // 2) Intenta sincronizar (si hay señal). Si no, queda pendiente.
    await _refreshPendingCount();
    _trySync();
  }

  void _trySync() {
    if (_online && !_syncing) {
      _syncNow();
    }
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    final pending = await PickupQueueDb.instance.pendingForStore(widget.store.id);
    if (pending.isEmpty) {
      await _refreshPendingCount();
      return;
    }
    setState(() => _syncing = true);
    try {
      final items = pending
          .map((s) => {
                'uuid': s.uuid,
                'code': s.code,
                'scanned_at': s.scannedAt.toIso8601String(),
              })
          .toList();

      final res = await widget.odooClient.scanPickupBatch(
        token: widget.token,
        storeId: widget.store.id,
        items: items,
      );

      if (res['success'] == true) {
        final results = (res['results'] as List?) ?? [];
        int ok = 0, err = 0;
        for (final r in results) {
          final m = r as Map;
          final uuid = m['uuid']?.toString() ?? '';
          final success = m['success'] == true;
          final status = success ? 'synced' : 'error';
          final number = m['order_number']?.toString() ?? '';
          final name = m['fullname']?.toString() ?? '';
          final created = m['created'] == true;
          final errMsg = m['error']?.toString() ?? '';

          await PickupQueueDb.instance.updateResult(
            uuid,
            status: status,
            orderNumber: number,
            fullname: name,
            created: created,
            errorMsg: errMsg,
          );
          _applySyncResult(uuid, status, number, name, created, errMsg);
          if (success) {
            ok++;
          } else {
            err++;
          }
        }
        if (mounted && (ok > 0 || err > 0)) {
          _snack(
            'Sincronizado: $ok ok${err > 0 ? ', $err con error' : ''}',
            err > 0 ? const Color(0xFFF59E0B) : _accent,
          );
        }
      }
      // Si falla la conexión, los pendientes quedan tal cual para reintentar.
    } catch (_) {
      // sin conexión / error de red -> se reintentará luego
    } finally {
      await _refreshPendingCount();
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _applySyncResult(String uuid, String status, String number, String name,
      bool created, String errMsg) {
    final i = _collected.indexWhere((c) => c.uuid == uuid);
    if (i < 0) return;
    setState(() {
      final c = _collected[i];
      c.status = status;
      c.created = created;
      c.errorMsg = errMsg;
      if (number.isNotEmpty) c.orderNumber = number;
      if (name.isNotEmpty) c.fullname = name;
    });
  }

  Future<void> _refreshPendingCount() async {
    final p =
        await PickupQueueDb.instance.countByStatus(widget.store.id, 'pending');
    final e =
        await PickupQueueDb.instance.countByStatus(widget.store.id, 'error');
    if (mounted) setState(() => _pendingCount = p + e);
  }

  Widget _syncBar() {
    final responsive = context.responsive;
    final synced = _collected.where((c) => c.status == 'synced').length;
    return Container(
      margin: EdgeInsets.only(bottom: responsive.getResponsiveSize(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _online ? const Color(0xFFEFF7EF) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_online ? const Color(0xFF22A06B) : const Color(0xFFF59E0B))
              .withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 18,
            color: _online ? const Color(0xFF22A06B) : const Color(0xFFB7791F),
          ),
          SizedBox(width: responsive.getResponsiveSize(8)),
          Expanded(
            child: Text(
              _online
                  ? 'En línea · $synced sincronizados · $_pendingCount pendientes'
                  : 'Sin conexión · $_pendingCount por sincronizar (guardados en el equipo)',
              style: TextStyle(
                fontSize: responsive.getResponsiveFontSize(12),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          if (_pendingCount > 0)
            TextButton.icon(
              onPressed: (_online && !_syncing) ? _syncNow : null,
              icon: _syncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync_rounded, size: 16),
              label: Text(_syncing ? 'Sincronizando' : 'Sincronizar'),
              style: TextButton.styleFrom(foregroundColor: _accent),
            ),
        ],
      ),
    );
  }

  /// Construye el mismo PDF de cargo que se utilizaba para impresión.
  Future<_BuiltCargoPdf> _buildCargoPdf() async {
    final ordered = [..._collected]..sort((a, b) => a.time.compareTo(b.time));
    final registro = ordered.first.time;
    final termino = ordered.last.time;

    final rows = <CargoScanRow>[];
    int totalBultos = 0;
    for (var i = 0; i < ordered.length; i++) {
      final mc = ordered[i].multipackCount;
      totalBultos += (mc >= 2) ? mc : 1;
      rows.add(CargoScanRow(
        index: i + 1,
        code: ordered[i].code,
        time: ordered[i].time,
        multipackCount: mc,
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
      totalBultos: totalBultos,
      rows: rows,
    );

    return _BuiltCargoPdf(
      bytes: bytes,
      fileName: CargoPdf.fileName(widget.store.fullName, termino),
    );
  }

  /// Guarda automáticamente el cargo en el dispositivo sin abrir impresión.
  Future<bool> _saveCargoPdf({bool showFeedback = false}) async {
    if (_collected.isEmpty || _generating) return false;
    setState(() => _generating = true);
    try {
      final built = await _buildCargoPdf();
      final saved = await CargoPdfStorage.save(
        bytes: built.bytes,
        fileName: built.fileName,
      );

      _cargoPdfPath = saved.path;
      _cargoPdfName = File(saved.path).uri.pathSegments.last;
      _cargoInPublicDownloads = saved.isPublicDownload;
      await _saveSession();

      if (mounted && showFeedback) {
        final where = saved.isPublicDownload
            ? 'Download/Trainyl/Cargos'
            : 'el almacenamiento de Trainyl';
        _snack('PDF guardado automáticamente en $where', const Color(0xFF16A34A));
      }
      return true;
    } catch (e) {
      if (mounted && showFeedback) {
        _snack(
          'Escaneo finalizado, pero no se pudo guardar el PDF: $e',
          const Color(0xFFEF4444),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// La vista de impresión solo se abre cuando el usuario lo solicita.
  Future<void> _openCargoPdf() async {
    if (_collected.isEmpty || _generating) return;
    setState(() => _generating = true);
    try {
      Uint8List? bytes;
      var fileName = _cargoPdfName;
      final path = _cargoPdfPath;

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
          fileName ??= file.uri.pathSegments.isNotEmpty
              ? file.uri.pathSegments.last
              : null;
        }
      }

      if (bytes == null) {
        final built = await _buildCargoPdf();
        final saved = await CargoPdfStorage.save(
          bytes: built.bytes,
          fileName: built.fileName,
        );
        bytes = built.bytes;
        fileName = built.fileName;
        _cargoPdfPath = saved.path;
        _cargoPdfName = File(saved.path).uri.pathSegments.last;
        _cargoInPublicDownloads = saved.isPublicDownload;
        await _saveSession();
      }

      await Printing.layoutPdf(
        onLayout: (_) async => bytes!,
        name: fileName ?? 'Cargo_Trainyl.pdf',
      );
    } catch (e) {
      if (mounted) {
        _snack('No se pudo abrir el cargo: $e', const Color(0xFFEF4444));
      }
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
            child: SafeArea(
              top: false,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
              padding: EdgeInsets.all(responsive.getResponsiveSize(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _syncBar(),
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
                        onPressed: _generating ? null : _openCargoPdf,
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
                              ? 'Abriendo...'
                              : 'Abrir / imprimir cargo (PDF)',
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
          ),
        ],
      ),
    );
  }
}

class _BuiltCargoPdf {
  final Uint8List bytes;
  final String fileName;

  const _BuiltCargoPdf({
    required this.bytes,
    required this.fileName,
  });
}

class _Collected {
  final String uuid;
  final String code;
  String orderNumber;
  String fullname;
  final DateTime time;
  String status; // pending | synced | error
  bool created;
  String errorMsg;
  int multipackCount; // 0 = normal, ≥2 = multibulto
  _Collected({
    required this.code,
    required this.orderNumber,
    required this.fullname,
    required this.time,
    this.uuid = '',
    this.status = 'synced',
    this.created = false,
    this.errorMsg = '',
    this.multipackCount = 0,
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
    final isPending = item.status == 'pending';
    final isError = item.status == 'error';
    final Color accent = isError
        ? const Color(0xFFEF4444)
        : (isPending ? const Color(0xFFF59E0B) : const Color(0xFF1A5BB5));
    final IconData icon = isError
        ? Icons.error_outline
        : (isPending ? Icons.schedule_rounded : Icons.check_rounded);
    final String label = isError
        ? 'Error'
        : (isPending ? 'Pendiente' : (item.created ? 'Creado' : 'Recogido'));
    return Container(
      margin: EdgeInsets.only(bottom: responsive.getResponsiveSize(8)),
      padding: EdgeInsets.all(responsive.getResponsiveSize(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: accent.withOpacity(0.30),
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
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 18),
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
                if (isError && item.errorMsg.isNotEmpty)
                  Text(
                    item.errorMsg,
                    style: TextStyle(
                      fontSize: responsive.getResponsiveFontSize(11.5),
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                if (item.multipackCount >= 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_rounded,
                            size: 13, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 4),
                        Text(
                          'Multibulto: ${item.multipackCount} bultos',
                          style: TextStyle(
                            fontSize: responsive.getResponsiveFontSize(11.5),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: accent,
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
