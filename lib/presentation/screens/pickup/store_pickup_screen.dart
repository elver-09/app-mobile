import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/pickup_store_model.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/screens/pickup/pickup_scan_screen.dart';
import 'package:trainyl_2_0/presentation/widgets/brand_header.dart';

/// Pantalla que indica a qué tienda(s) va el conductor a recoger.
/// Si tiene 1 tienda asignada la muestra directo; si tiene varias, lista para elegir.
class StorePickupScreen extends StatefulWidget {
  final String token;
  final OdooClient odooClient;
  final Map<String, dynamic> driver;

  const StorePickupScreen({
    super.key,
    required this.token,
    required this.odooClient,
    required this.driver,
  });

  @override
  State<StorePickupScreen> createState() => _StorePickupScreenState();
}

class _StorePickupScreenState extends State<StorePickupScreen> {
  static const _accent = Color(0xFF1A5BB5);
  static const _bgTint = Color(0xFFEEF3FB);

  late Future<PickupStoresResult> _storesFuture;

  @override
  void initState() {
    super.initState();
    _storesFuture = widget.odooClient.fetchPickupStores(widget.token);
  }

  void _reload() {
    setState(() {
      _storesFuture = widget.odooClient.fetchPickupStores(widget.token);
    });
  }

  void _goScan(PickupStore store, String placa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickupScanScreen(
          token: widget.token,
          odooClient: widget.odooClient,
          store: store,
          driver: widget.driver,
          placa: placa,
        ),
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
                responsive.getResponsiveSize(16),
                responsive.getResponsiveSize(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      SizedBox(width: responsive.getResponsiveSize(12)),
                      Icon(Icons.store_mall_directory_rounded,
                          color: Colors.white.withOpacity(0.95),
                          size: responsive.iconSize),
                      SizedBox(width: responsive.getResponsiveSize(8)),
                      Flexible(
                        child: Text(
                          'Recojo en tienda',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: responsive.getResponsiveFontSize(20),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.getResponsiveSize(12)),
                  Text(
                    'Elige la tienda a la que vas a ir y escanea ahí los pedidos',
                    style: TextStyle(
                      fontSize: responsive.getResponsiveFontSize(12.5),
                      color: Colors.white.withOpacity(0.85),
                      height: 1.3,
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
              child: FutureBuilder<PickupStoresResult>(
                future: _storesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(onRetry: _reload, message: '${snapshot.error}');
                  }

                  final stores = snapshot.data?.stores ?? [];
                  final placa = snapshot.data?.placa ?? '';
                  if (stores.isEmpty) {
                    return _EmptyState(onRetry: _reload);
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      responsive.getResponsiveSize(16),
                      responsive.getResponsiveSize(16),
                      responsive.getResponsiveSize(16),
                      responsive.getResponsiveSize(24),
                    ),
                    children: [
                      Row(
                        children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            stores.length == 1
                                ? '1 tienda asignada'
                                : '${stores.length} tiendas asignadas',
                            style: TextStyle(
                              fontSize: responsive.getResponsiveFontSize(12.5),
                              color: _accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.getResponsiveSize(14)),
                    ...stores.map(
                      (store) => Padding(
                        padding: EdgeInsets.only(
                          bottom: responsive.getResponsiveSize(14),
                        ),
                        child: _StoreCard(
                          store: store,
                          single: stores.length == 1,
                          onTap: () => _goScan(store, placa),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final PickupStore store;
  final bool single;
  final VoidCallback onTap;

  const _StoreCard({
    required this.store,
    required this.single,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius + 4),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C80).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(responsive.getResponsiveSize(12)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A7AE4), Color(0xFF143C82)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF123C80).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: responsive.iconSize,
                  ),
                ),
                SizedBox(width: responsive.getResponsiveSize(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (store.client.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A5BB5).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            store.sellerCode.isNotEmpty
                                ? '${store.client} · ${store.sellerCode}'
                                : store.client,
                            style: TextStyle(
                              fontSize: responsive.getResponsiveFontSize(11),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A5BB5),
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.getResponsiveSize(6)),
                      ],
                      Text(
                        store.name,
                        style: TextStyle(
                          fontSize: responsive.getResponsiveFontSize(17.5),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: responsive.getResponsiveSize(3)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Color(0xFF94A3B8)),
                          SizedBox(width: responsive.getResponsiveSize(4)),
                          Expanded(
                            child: Text(
                              store.address.isNotEmpty
                                  ? store.address
                                  : 'Sin dirección registrada',
                              style: TextStyle(
                                fontSize: responsive.getResponsiveFontSize(12.5),
                                color: const Color(0xFF64748B),
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(responsive.borderRadius + 4),
                bottomRight: Radius.circular(responsive.borderRadius + 4),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: responsive.getResponsiveSize(13),
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4FA0), Color(0xFF0E2C63)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(responsive.borderRadius + 4),
                    bottomRight: Radius.circular(responsive.borderRadius + 4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: responsive.getResponsiveSize(8)),
                    Text(
                      single ? 'Escanear pedidos' : 'Ir y escanear',
                      style: TextStyle(
                        fontSize: responsive.getResponsiveFontSize(15),
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.getResponsiveSize(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5BB5).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_outlined,
                  size: responsive.iconSize * 2, color: const Color(0xFF1A5BB5)),
            ),
            SizedBox(height: responsive.getResponsiveSize(14)),
            Text(
              'No tienes tiendas de recogida asignadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.getResponsiveFontSize(15),
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: responsive.getResponsiveSize(12)),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;
  const _ErrorState({required this.onRetry, required this.message});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.getResponsiveSize(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: responsive.iconSize * 2, color: const Color(0xFFEF4444)),
            ),
            SizedBox(height: responsive.getResponsiveSize(14)),
            Text(
              'No se pudieron cargar las tiendas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.getResponsiveFontSize(15),
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: responsive.getResponsiveSize(12)),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
