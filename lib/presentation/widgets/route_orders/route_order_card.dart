import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import '../../screens/order_detail_screen.dart';

class RouteOrderCard extends StatelessWidget {
  final OrderItem order;
  final String token;
  final OdooClient odooClient;
  final String? routeName;
  final VoidCallback? onTap;

  const RouteOrderCard({
    super.key,
    required this.order,
    required this.token,
    required this.odooClient,
    this.routeName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _navigateToOrderDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(),
              const SizedBox(height: 12),
              _buildContactInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.fullname,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.orderNumber,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildProductInfo(),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(order.statusLabel),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            order.statusLabel,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.fullname,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_rounded,
                  size: 15,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  order.phone ?? 'Sin teléfono',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Text(
      'Producto: ${order.product ?? 'N/A'} · Zona ${order.district}',
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF8B95A1),
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('curso')) return const Color(0xFFF59E0B);
    if (normalized.contains('pendiente')) return const Color(0xFF3B82F6);
    if (normalized.contains('entregado')) return const Color(0xFF10B981);
    if (normalized.contains('rechaz')) return const Color(0xFFEF4444);
    if (normalized.contains('no dispo')) return const Color(0xFFF59E0B);
    return const Color(0xFF94A3B8);
  }

  void _navigateToOrderDetail(BuildContext context) {
    print(
      '📦 Orden: ${order.orderNumber} - Lat: ${order.latitude}, Lng: ${order.longitude}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          orderId: order.id,
          orderNumber: order.orderNumber,
          clientName: order.fullname,
          phone: order.phone ?? '',
          address: order.address,
          product: order.product ?? 'N/A',
          district: order.district,
          token: token,
          odooClient: odooClient,
          routeName: routeName,
          latitude: order.latitude ?? -8.00295,
          longitude: order.longitude ?? -78.3163062,
          googleMapsUrl: order.googleMapsUrl ?? '',
          planningStatus: order.planningStatus,
        ),
      ),
    );
  }
}
