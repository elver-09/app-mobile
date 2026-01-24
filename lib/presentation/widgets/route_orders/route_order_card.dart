import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import '../../screens/order_detail_screen.dart';

class RouteOrderCard extends StatelessWidget {
  final OrderItem order;
  final String token;
  final String? routeName;
  final VoidCallback? onTap;

  const RouteOrderCard({
    super.key,
    required this.order,
    required this.token,
    this.routeName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _navigateToOrderDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          order.orderNumber,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: order.statusColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            order.statusLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToOrderDetail(BuildContext context) {
    print('📦 Orden: ${order.orderNumber} - Lat: ${order.latitude}, Lng: ${order.longitude}');
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
          routeName: routeName,
          latitude: order.latitude ?? -8.00295,
          longitude: order.longitude ?? -78.3163062,
          googleMapsUrl: order.googleMapsUrl ?? '',
        ),
      ),
    );
  }
}
