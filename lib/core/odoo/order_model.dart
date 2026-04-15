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
  final int? reasonRejectionId;
  final bool isMultipack;
  final int multipackCount;
  final int expectedPackages;
  final int scannedPackages;
  final int remainingPackages;

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
    this.reasonRejectionId,
    this.isMultipack = false,
    this.multipackCount = 0,
    this.expectedPackages = 1,
    this.scannedPackages = 0,
    this.remainingPackages = 0,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final multipackCount = _toInt(json['multipack_count']);
    final expectedPackages = _toInt(
      json['expected_packages'],
      defaultValue: multipackCount > 1 ? multipackCount : 1,
    );
    final scannedPackages = _toInt(json['scanned_packages']);
    final remainingPackages = _toInt(
      json['remaining_packages'],
      defaultValue: expectedPackages - scannedPackages,
    );

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
      planningStatus: json['new_status_orders'] as String? ?? json['planning_status'] as String? ?? 'planned',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      sequence: _toInt(json['sequence'], defaultValue: -1) >= 0 ? _toInt(json['sequence']) : null,
      routeSequence: _toInt(json['route_sequence'], defaultValue: -1) >= 0 ? _toInt(json['route_sequence']) : null,
      reasonRejectionId: _toInt(json['reason_rejection_id'], defaultValue: -1) >= 0 ? _toInt(json['reason_rejection_id']) : null,
      isMultipack: json['is_multipack'] == true,
      multipackCount: multipackCount,
      expectedPackages: expectedPackages,
      scannedPackages: scannedPackages,
      remainingPackages: remainingPackages < 0 ? 0 : remainingPackages,
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
    int? reasonRejectionId,
    bool? isMultipack,
    int? multipackCount,
    int? expectedPackages,
    int? scannedPackages,
    int? remainingPackages,
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
      reasonRejectionId: reasonRejectionId ?? this.reasonRejectionId,
      isMultipack: isMultipack ?? this.isMultipack,
      multipackCount: multipackCount ?? this.multipackCount,
      expectedPackages: expectedPackages ?? this.expectedPackages,
      scannedPackages: scannedPackages ?? this.scannedPackages,
      remainingPackages: remainingPackages ?? this.remainingPackages,
    );
  }
}

// Modelo para agrupar órdenes por cliente y dirección
class GroupedOrder {
  final String clientName;
  final String address;
  final String? phone;
  final List<OrderItem> orders;
  final double? latitude;
  final double? longitude;

  GroupedOrder({
    required this.clientName,
    required this.address,
    this.phone,
    required this.orders,
    this.latitude,
    this.longitude,
  });

  /// Cuenta órdenes por estado
  int get totalOrders => orders.length;
  
  int get deliveredCount => orders.where((o) => o.planningStatus == 'delivered').length;
  
  int get rejectedCount => orders.where((o) => 
    o.planningStatus == 'cancelled' ||
    o.planningStatus == 'anulled' ||
    o.planningStatus == 'returned' ||
    o.planningStatus == 'cancelled_origin'
  ).length;
  
  int get pendingCount => orders.where((o) =>
    o.planningStatus == 'in_transport' ||
    o.planningStatus == 'start_of_route' ||
    o.planningStatus == 'blocked'
  ).length;

  /// Retorna órdenes pendientes
  List<OrderItem> get pendingOrders => orders.where((o) =>
    o.planningStatus == 'in_transport' ||
    o.planningStatus == 'start_of_route' ||
    o.planningStatus == 'blocked'
  ).toList();

  /// Agrupa órdenes por cliente y dirección
  static List<GroupedOrder> groupOrders(List<OrderItem> orders) {
    final Map<String, GroupedOrder> groupedMap = {};

    for (final order in orders) {
      final key = '${order.fullname}|${order.address}';
      
      if (groupedMap.containsKey(key)) {
        groupedMap[key]!.orders.add(order);
      } else {
        groupedMap[key] = GroupedOrder(
          clientName: order.fullname,
          address: order.address,
          phone: order.phone,
          orders: [order],
          latitude: order.latitude,
          longitude: order.longitude,
        );
      }
    }

    return groupedMap.values.toList();
  }
}
