import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/screens/choose_sede.dart';
import 'package:trainyl_2_0/presentation/screens/pickup/store_pickup_screen.dart';

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
    final driverName = (driver['name'] as String?)?.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(responsive.getResponsiveSize(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsive.getResponsiveSize(8)),
              Text(
                driverName != null && driverName.isNotEmpty
                    ? 'Hola, $driverName'
                    : 'Hola',
                style: TextStyle(
                  fontSize: responsive.headingLargeFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: responsive.getResponsiveSize(4)),
              Text(
                '¿Qué vas a hacer hoy?',
                style: TextStyle(
                  fontSize: responsive.bodyMediumFontSize,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: responsive.getResponsiveSize(28)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeCard(
                      icon: Icons.local_shipping_rounded,
                      title: 'Entregar pedidos',
                      subtitle: 'Continúa con tus rutas y entregas del día',
                      gradient: const [Color(0xFF2A7AE4), Color(0xFF123C80)],
                      onTap: () => _goDelivery(context),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(18)),
                    _ModeCard(
                      icon: Icons.store_mall_directory_rounded,
                      title: 'Recoger en tienda',
                      subtitle: 'Ve a la tienda y escanea los pedidos a recoger',
                      gradient: const [Color(0xFF0EA5A4), Color(0xFF0F766E)],
                      onTap: () => _goPickup(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(responsive.borderRadius + 6),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.all(responsive.getResponsiveSize(20)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(responsive.borderRadius + 6),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.getResponsiveSize(14)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: TextStyle(
                        fontSize: responsive.headingMediumFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(4)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: responsive.bodySmallFontSize,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.9),
                size: responsive.iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
