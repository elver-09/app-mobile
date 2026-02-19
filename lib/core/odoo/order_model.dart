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
  final int? sequence;
  final int? routeSequence;

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
    this.sequence,
    this.routeSequence,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      orderNumber:
          json['display_name'] as String? ??
          json['order_number'] as String? ??
          '',
      fullname: json['fullname'] as String? ?? '',
      clientName: json['client_name'] as String?,
      district: json['district'] as String? ?? '',
      address: json['address'] as String? ?? '',
      product: json['product'] as String?,
      phone: json['phone'] as String?,
      planningStatus: json['planning_status'] as String? ?? 'planned',
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      sequence: json['sequence'] as int?,
      routeSequence: json['route_sequence'] as int?,
    );
  }

  Color get statusColor {
    switch (planningStatus) {
      case 'in_planification':
      case 'pending':
        return const Color(0xFF8B95A4); // gris/plomo - "Pendiente"
      case 'blocked':
        return const Color(0xFF8B5CF6); // morado - "Bloqueado"
      case 'in_transport':
        return const Color(0xFF3B82F6); // azul - "En transporte"
      case 'start_of_route':
        return const Color(0xFFF59E0B); // amarillo/naranja - "En curso"
      case 'delivered':
        return const Color(0xFF10B981); // verde - "Entregado"
      case 'cancelled':
      case 'anulled':
      case 'returned':
      case 'cancelled_origin':
        return const Color(
          0xFFEF4444,
        ); // rojo - "Rechazado" (por compatibilidad)
      case 'unavailable':
        return const Color(0xFFF97316); // naranja - "No disponible"
      default:
        return const Color(0xFF9CA3AF); // gris por defecto
    }
  }

  String get statusLabel {
    switch (planningStatus) {
      case 'in_planification':
      case 'pending':
        return 'Pendiente';
      case 'blocked':
        return 'Bloqueado';
      case 'in_transport':
        return 'Transporte';
      case 'start_of_route':
        return 'En curso';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
      case 'anulled':
      case 'returned':
      case 'cancelled_origin':
        return 'Rechazado'; // Por compatibilidad
      case 'unavailable':
        return 'No disponible';
      default:
        return 'Pendiente';
    }
  }

  // Método para crear una copia con valores actualizados
  OrderItem copyWith({
    int? id,
    String? orderNumber,
    String? fullname,
    String? clientName,
    String? district,
    String? address,
    String? product,
    String? phone,
    String? planningStatus,
    double? latitude,
    double? longitude,
    int? sequence,
    int? routeSequence,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      fullname: fullname ?? this.fullname,
      clientName: clientName ?? this.clientName,
      district: district ?? this.district,
      address: address ?? this.address,
      product: product ?? this.product,
      phone: phone ?? this.phone,
      planningStatus: planningStatus ?? this.planningStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sequence: sequence ?? this.sequence,
      routeSequence: routeSequence ?? this.routeSequence,
    );
  }
}
