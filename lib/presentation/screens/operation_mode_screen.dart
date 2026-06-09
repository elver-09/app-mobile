import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/screens/choose_sede.dart';
import 'package:trainyl_2_0/presentation/screens/pickup/store_pickup_screen.dart';
import 'package:trainyl_2_0/presentation/widgets/brand_header.dart';

/// Pantalla que se muestra justo después del login para que el conductor
/// elija entre ENTREGAR pedidos (flujo actual) o RECOGER en tienda (flujo nuevo).
class OperationModeScreen extends StatelessWidget {
  final String token;
  final OdooClient odooClient;
  final Map<String, dynamic> driver;

  const OperationModeScreen({
    super.key,
    required this.token,
    required this.odooClient,
    required this.driver,
  });

  static const _bgTint = Color(0xFFEEF3FB);

  void _goDelivery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChooseSede(
          token: token,
          odooClient: odooClient,
          driver: driver,
        ),
      ),
    );
  }

  void _goPickup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StorePickupScreen(
          token: token,
          odooClient: odooClient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final topInset = MediaQuery.of(context).padding.top;
    final driverName = (driver['name'] as String?)?.trim();

    return Scaffold(
      backgroundColor: _bgTint,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgTint, Color(0xFFF8FAFC)],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Encabezado curvo corporativo ─────────────────────────────
              BrandHeader(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.getResponsiveSize(22),
                    topInset + responsive.getResponsiveSize(22),
                    responsive.getResponsiveSize(22),
                    responsive.getResponsiveSize(54),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.waving_hand_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Bienvenido',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: responsive.getResponsiveFontSize(12.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: responsive.getResponsiveSize(14)),
                      Text(
                        driverName != null && driverName.isNotEmpty
                            ? driverName
                            : 'Conductor',
                        style: TextStyle(
                          fontSize: responsive.getResponsiveFontSize(27),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: responsive.getResponsiveSize(4)),
                      Text(
                        '¿Qué vas a hacer hoy?',
                        style: TextStyle(
                          fontSize: responsive.getResponsiveFontSize(15),
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tarjetas (se superponen al encabezado) ────────────────────
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.getResponsiveSize(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded,
                                size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: responsive.getResponsiveSize(6)),
                            Text(
                              'Selecciona una opción',
                              style: TextStyle(
                                fontSize: responsive.getResponsiveFontSize(12.5),
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.getResponsiveSize(14)),
                        _ModeCard(
                          icon: Icons.local_shipping_rounded,
                          title: 'Entregar pedidos',
                          subtitle: 'Continúa con tus rutas y entregas del día',
                          gradient: const [Color(0xFF2A7AE4), Color(0xFF143C82)],
                          onTap: () => _goDelivery(context),
                        ),
                        SizedBox(height: responsive.getResponsiveSize(16)),
                        _ModeCard(
                          icon: Icons.storefront_rounded,
                          title: 'Recoger en tienda',
                          subtitle: 'Ve a la tienda y escanea los pedidos a recoger',
                          gradient: const [Color(0xFF1B4FA0), Color(0xFF0E2C63)],
                          onTap: () => _goPickup(context),
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: responsive.getResponsiveSize(16),
                          ),
                          child: Text(
                            'Trainyl · Logística inteligente',
                            style: TextStyle(
                              fontSize: responsive.getResponsiveFontSize(12.5) * 0.95,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.all(responsive.getResponsiveSize(20)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(responsive.borderRadius + 8),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.last.withOpacity(0.38),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(responsive.borderRadius + 8),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -22,
                  child: Icon(
                    widget.icon,
                    size: 120,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(responsive.getResponsiveSize(14)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius:
                            BorderRadius.circular(responsive.borderRadius),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: responsive.iconSize * 1.4,
                      ),
                    ),
                    SizedBox(width: responsive.getResponsiveSize(16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: responsive.getResponsiveFontSize(17.5),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: responsive.getResponsiveSize(4)),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: responsive.getResponsiveFontSize(12.5),
                              color: Colors.white.withOpacity(0.9),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
