import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import '../../screens/order_detail_screen.dart';
import 'start_order_button.dart';

class RouteOrderCard extends StatefulWidget {
  final OrderItem order;
  final String token;
  final OdooClient odooClient;
  final String? routeName;
  final VoidCallback? onTap;
  final VoidCallback? onStartRouteSuccess;
  final bool isActive;
  final bool isDisabled;
  final int routeId;
  final double? routeStartLatitude;
  final double? routeStartLongitude;
  final List<OrderItem> allOrders;

  const RouteOrderCard({
    super.key,
    required this.order,
    required this.token,
    required this.odooClient,
    this.routeName,
    this.onTap,
    this.onStartRouteSuccess,
    this.isActive = false,
    this.isDisabled = false,
    this.routeId = 0,
    this.routeStartLatitude,
    this.routeStartLongitude,
    this.allOrders = const [],
  });

  @override
  State<RouteOrderCard> createState() => _RouteOrderCardState();
}

class _RouteOrderCardState extends State<RouteOrderCard> {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : (widget.onTap ?? () => _navigateToOrderDetail(context)),
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
              color: widget.isActive 
                ? const Color(0xFFFEF3C7) // Amarillo suave si está activa
                : const Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isActive 
                  ? const Color(0xFFF59E0B) // Borde amarillo si está activa
                  : const Color(0xFFE5E7EB), 
                width: widget.isActive ? 2 : 1,
              ),
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
                widget.order.fullname,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.order.orderNumber,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(widget.order.statusLabel),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                widget.order.statusLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            // Botón "Iniciar" para órdenes pendientes
            if (widget.order.planningStatus == 'pending') ...[
              const SizedBox(height: 8),
              StartOrderButton(
                orderId: widget.order.id,
                routeId: widget.routeId,
                orderNumber: widget.order.orderNumber,
                token: widget.token,
                odooClient: widget.odooClient,
                onSuccess: widget.onStartRouteSuccess,
                allOrders: widget.allOrders,
              ),
            ],
          ],
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
                  widget.order.address,
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
              widget.order.fullname,
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
                  widget.order.phone ?? 'Sin teléfono',
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
      'Producto: ${widget.order.product ?? 'N/A'} · Zona ${widget.order.district}',
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

  void _navigateToOrderDetail(BuildContext context) {
    print(
      '📦 Orden: ${widget.order.orderNumber} - Lat: ${widget.order.latitude}, Lng: ${widget.order.longitude}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          orderId: widget.order.id,
          orderNumber: widget.order.orderNumber,
          clientName: widget.order.fullname,
          phone: widget.order.phone ?? '',
          address: widget.order.address,
          product: widget.order.product ?? 'N/A',
          district: widget.order.district,
          token: widget.token,
          odooClient: widget.odooClient,
          routeName: widget.routeName,
          latitude: widget.order.latitude,
          longitude: widget.order.longitude,
          planningStatus: widget.order.planningStatus,
          routeId: widget.routeId,
        ),
      ),
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
}
