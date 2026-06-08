import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/pickup_store_model.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/screens/pickup/pickup_scan_screen.dart';

/// Pantalla que indica a qué tienda(s) va el conductor a recoger.
/// Si tiene 1 tienda asignada la muestra directo; si tiene varias, lista para elegir.
class StorePickupScreen extends StatefulWidget {
  final String token;
  final OdooClient odooClient;

  const StorePickupScreen({
    super.key,
    required this.token,
    required this.odooClient,
  });

  @override
  State<StorePickupScreen> createState() => _StorePickupScreenState();
}

class _StorePickupScreenState extends State<StorePickupScreen> {
  late Future<List<PickupStore>> _storesFuture;

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

  void _goScan(PickupStore store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickupScanScreen(
          token: widget.token,
          odooClient: widget.odooClient,
          store: store,
        ),
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
        title: const Text(
          'Recojo en tienda',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<PickupStore>>(
          future: _storesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _reload, message: '${snapshot.error}');
            }

            final stores = snapshot.data ?? [];
            if (stores.isEmpty) {
              return _EmptyState(onRetry: _reload);
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stores.length == 1
                        ? 'Vas a recoger en esta tienda:'
                        : 'Elige la tienda a la que vas a ir:',
                    style: TextStyle(
                      fontSize: responsive.bodyMediumFontSize,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
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
                        onTap: () => _goScan(store),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.getResponsiveSize(10)),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5A4).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                ),
                child: Icon(
                  Icons.store_mall_directory_rounded,
                  color: const Color(0xFF0F766E),
                  size: responsive.iconSize,
                ),
              ),
              SizedBox(width: responsive.getResponsiveSize(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: TextStyle(
                        fontSize: responsive.headingMediumFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (store.address.isNotEmpty) ...[
                      SizedBox(height: responsive.getResponsiveSize(4)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: responsive.iconSize * 0.7,
                            color: const Color(0xFF64748B),
                          ),
                          SizedBox(width: responsive.getResponsiveSize(4)),
                          Expanded(
                            child: Text(
                              store.address,
                              style: TextStyle(
                                fontSize: responsive.bodySmallFontSize,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.getResponsiveSize(14)),
          SizedBox(
            width: double.infinity,
            height: responsive.buttonHeight * 0.85,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              label: Text(
                single ? 'Escanear pedidos' : 'Ir y escanear',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
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
            Icon(Icons.store_outlined,
                size: responsive.iconSize * 2.5, color: const Color(0xFFCBD5E1)),
            SizedBox(height: responsive.getResponsiveSize(12)),
            Text(
              'No tienes tiendas de recogida asignadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.bodyMediumFontSize,
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
            Icon(Icons.error_outline,
                size: responsive.iconSize * 2.5, color: const Color(0xFFEF4444)),
            SizedBox(height: responsive.getResponsiveSize(12)),
            Text(
              'No se pudieron cargar las tiendas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.bodyMediumFontSize,
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
