import 'package:flutter/material.dart';

class OrderItem {
  final int id;
  final String orderNumber;
  final String fullname;
  final String? clientName;
  final String district;
  final String address;
  final String? product;
  final String? phone;
  final String planningStatus;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;

  OrderItem({
    required this.id,
    required this.orderNumber,
    required this.fullname,
    this.clientName,
    required this.district,
    required this.address,
    this.product,
    this.phone,
    required this.planningStatus,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      orderNumber: json['display_name'] as String? ?? json['order_number'] as String? ?? '',
      fullname: json['fullname'] as String? ?? '',
      clientName: json['client_name'] as String?,
      district: json['district'] as String? ?? '',
      address: json['address'] as String? ?? '',
      product: json['product'] as String?,
      phone: json['phone'] as String?,
      planningStatus: json['planning_status'] as String? ?? 'planned',
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      googleMapsUrl: json['google_maps_url'] as String?,
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
