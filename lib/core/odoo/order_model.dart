import 'package:flutter/material.dart';

class OrderItem {
  final String orderNumber;
  final String fullname;
  final String? clientName;
  final String district;
  final String address;
  final String? product;
  final String? phone;
  final String planningStatus; // in_progress, pending, delivered, rejected, unavailable

  OrderItem({
    required this.orderNumber,
    required this.fullname,
    this.clientName,
    required this.district,
    required this.address,
    this.product,
    this.phone,
    required this.planningStatus,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderNumber: json['order_number'] as String? ?? '',
      fullname: json['fullname'] as String? ?? '',
      clientName: json['client_name'] as String?,
      district: json['district'] as String? ?? '',
      address: json['address'] as String? ?? '',
      product: json['product'] as String?,
      phone: json['phone'] as String?,
      planningStatus: json['planning_status'] as String? ?? 'pending',
    );
  }

  Color get statusColor {
    switch (planningStatus) {
      case 'in_progress':
        return const Color(0xFFF59E0B); // amarillo/naranja - "En curso"
      case 'pending':
        return const Color(0xFF2563EB); // azul - "Pendiente"
      case 'delivered':
        return const Color(0xFF10B981); // verde - "Entregado"
      case 'rejected':
        return const Color(0xFFEF4444); // rojo - "Rechazado"
      case 'unavailable':
        return const Color(0xFFF97316); // naranja - "No disponible"
      default:
        return const Color(0xFF9CA3AF); // gris por defecto
    }
  }

  String get statusLabel {
    switch (planningStatus) {
      case 'in_progress':
        return 'En curso';
      case 'pending':
        return 'Pendiente';
      case 'delivered':
        return 'Entregado';
      case 'rejected':
        return 'Rechazado';
      case 'unavailable':
        return 'No disponible';
      default:
        return 'Pendiente';
    }
  }
}
