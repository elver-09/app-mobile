import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import '../../screens/order_detail_screen.dart';

class RouteOrderCard extends StatelessWidget {
  final OrderItem order;
  final String token;
  final VoidCallback? onTap;

  const RouteOrderCard({
    super.key,
    required this.order,
    required this.token,
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
            const SizedBox(height: 12),
            _buildProductInfo(),
            const SizedBox(height: 12),
            _buildAddressInfo(),
            const SizedBox(height: 16),
            _buildContactInfo(),
          ],
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
                order.clientName ?? 'Cliente',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.orderNumber,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
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

  Widget _buildProductInfo() {
    return Text(
      'Producto: ${order.product ?? 'N/A'} · Zona ${order.district}',
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 18,
          color: Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            order.address,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            order.fullname,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            const Icon(
              Icons.phone,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Text(
              order.phone ?? '+56 9 0000 0000',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
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
          phone: order.phone ?? '+56 9 0000 0000',
          address: order.address,
          product: order.product ?? 'N/A',
          district: order.district,
          reference: order.address,
          token: token,
          latitude: order.latitude ?? -8.00295,
          longitude: order.longitude ?? -78.3163062,
          googleMapsUrl: order.googleMapsUrl ?? '',
        ),
      ),
    );
  }
}
