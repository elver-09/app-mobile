import 'package:trainyl_2_0/core/constants/route_status.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';

class RouteItem {
  final int id;
  final String name;
  final String zone;
  final String? fleet;
  final String? rutaDate;
  final int ordersQty;
  // Campos para compatibilidad (se calculan internamente si es necesario)
  final int planned;
  final int confirmed;
  final int delivered;
  final double confirmedPercent;
  final List<OrderItem> orders;

  RouteItem({
    required this.id,
    required this.name,
    required this.zone,
    this.fleet,
    this.rutaDate,
    required this.ordersQty,
    this.planned = 0,
    this.confirmed = 0,
    this.delivered = 0,
    this.confirmedPercent = 0.0,
    this.orders = const [],
  });

  factory RouteItem.fromJson(Map<String, dynamic> json) {
    return RouteItem(
      id: json['id'] as int,
      name: json['name'] as String,
      zone: json['zone'] as String? ?? '',
      fleet: json['fleet'] as String?,
      rutaDate: json['ruta_date'] as String?,
      ordersQty: json['orders_qty'] as int? ?? 0,
    );
  }

  /// Calcula el estado de la ruta basado en las órdenes
  RouteStatus get status {
    if (orders.isEmpty) {
      return RouteStatus.pending;
    }

    final completedOrders = orders
        .where((order) => order.planningStatus != 'pending')
        .length;

    if (completedOrders >= orders.length && orders.isNotEmpty) {
      return RouteStatus.completed;
    }
    return RouteStatus.pending;
  }

  /// Obtiene el color basado en el estado
  int getStatusColor() {
    return status.colorInt;
  }

  /// Retorna si hay órdenes completadas (no pendientes)
  bool get inProgress {
    final completedOrders =
        orders.where((order) => order.planningStatus != 'pending').length;
    return completedOrders > 0;
  }

  /// Calcula el progreso como fracción basado en órdenes completadas
  double get progressValue {
    if (ordersQty == 0) return 0;
    final completedOrders =
        orders.where((order) => order.planningStatus != 'pending').length;
    return completedOrders / ordersQty;
  }

  /// Formatea el texto de progreso
  String get progressText {
    final pendingCount =
        orders.where((order) => order.planningStatus == 'pending').length;
    return 'Pendiente $pendingCount / $ordersQty órdenes';
  }

  /// Cuenta órdenes pendientes
  int get pendingOrdersCount =>
      orders.where((order) => order.planningStatus == 'pending').length;

  int get statusCount {
    if (orders.isEmpty) {
      return 0;
    }
    return orders.where((order) => order.planningStatus != 'pending').length;
  }

  String get statusDisplay {
    final completedOrders =
        orders.where((order) => order.planningStatus != 'pending').length;
    return 'Terminado · $completedOrders/$ordersQty';
  }
}
