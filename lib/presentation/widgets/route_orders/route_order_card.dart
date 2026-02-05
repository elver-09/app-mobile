import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'dart:math';
import '../../screens/order_detail_screen.dart';

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
  bool _isLoadingStartRoute = false;

  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Future<bool> _isFirstOrderToStart() async {
    // Solo mostrar si la orden está pending
    if (widget.order.planningStatus != 'pending') {
      return false;
    }

    // No mostrar si ya hay alguna orden iniciada o completada
    bool hasStartedOrCompleted = widget.allOrders.any((order) {
      final status = order.planningStatus;
      return status == 'start_of_route' ||
          status == 'delivered' ||
          status == 'cancelled' ||
          status == 'anulled' ||
          status == 'returned' ||
          status == 'cancelled_origin' ||
          status == 'hand_to_hand';
    });

    if (hasStartedOrCompleted) {
      return false;
    }

    // Obtener órdenes pending
    final pendingOrders = widget.allOrders.where(
      (order) => order.planningStatus == 'pending'
    ).toList();

    if (pendingOrders.isEmpty || widget.routeStartLatitude == null || widget.routeStartLongitude == null) {
      return false;
    }

    // Encontrar la orden más cercana
    OrderItem closestOrder = pendingOrders.first;
    double minDistance = double.maxFinite;

    if (closestOrder.latitude != null && closestOrder.longitude != null) {
      minDistance = _haversineDistance(
        widget.routeStartLatitude!,
        widget.routeStartLongitude!,
        closestOrder.latitude!,
        closestOrder.longitude!,
      );
    }

    for (var order in pendingOrders.skip(1)) {
      if (order.latitude != null && order.longitude != null) {
        double distance = _haversineDistance(
          widget.routeStartLatitude!,
          widget.routeStartLongitude!,
          order.latitude!,
          order.longitude!,
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestOrder = order;
        }
      }
    }

    return closestOrder.id == widget.order.id;
  }

  Future<void> _startRoute() async {
    setState(() {
      _isLoadingStartRoute = true;
    });

    try {
      final result = await widget.odooClient.startNextOrder(
        token: widget.token,
        routeId: widget.routeId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        print('✅ Ruta iniciada: ${result['order_number']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ruta iniciada: ${result['order_number']}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStartRouteSuccess?.call();
      } else {
        print('❌ Error al iniciar ruta: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error'] ?? 'Desconocido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ Exception en _startRoute: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStartRoute = false;
        });
      }
    }
  }

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
                if (widget.order.sequence != null || widget.order.distanceKm != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildDeliveryInfo(),
                  ),
                // Botón "Iniciar ruta" si es la primera orden
                if (widget.order.planningStatus == 'pending')
                  FutureBuilder<bool>(
                    future: _isFirstOrderToStart(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (snapshot.data == true) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingStartRoute ? null : _startRoute,
                              icon: _isLoadingStartRoute
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.route, size: 18),
                              label: const Text('Iniciar ruta'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
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
        // Badge de secuencia si existe
        if (widget.order.sequence != null)
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: widget.isActive 
                ? const Color(0xFFF59E0B)
                : const Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.order.sequence}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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

  Widget _buildDeliveryInfo() {
    return Row(
      children: [
        if (widget.order.distanceKm != null) ...[
          const Icon(
            Icons.route,
            size: 14,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.order.distanceKm!.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
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
