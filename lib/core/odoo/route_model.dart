import 'package:trainyl_2_0/core/constants/route_status.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';

class RouteItem {
  final int id;
  final String name;
  final String zone;
  final String? fleet;
  final String? rutaDate;
  final int ordersQty;
  final String? stateRoute;
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
    this.stateRoute,
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
      stateRoute: json['state_route'] as String?,
    );
  }

  static const Set<String> _completedStatuses = {
    'delivered',
    'cancelled',
    'anulled',
    'returned',
    'cancelled_origin',
    'hand_to_hand',
  };

  static const Set<String> _pendingStatuses = {
    'pending',
    'planned',
    'start_of_route',
    'unavailable',
    'draft',
    'in_trainyl',
    'ready_for_drivin',
  };

  bool _isCompletedStatus(String status) => _completedStatuses.contains(status);

  bool _isPendingStatus(String status) =>
      _pendingStatuses.contains(status) || !_completedStatuses.contains(status);

  /// Calcula el estado de la ruta basado en las órdenes
  RouteStatus get status {
    if (stateRoute != null && stateRoute!.isNotEmpty) {
      switch (stateRoute) {
        case 'to_validate':
          return RouteStatus.toValidate;
        case 'in_route':
          return RouteStatus.inRoute;
        case 'finished':
          return RouteStatus.finished;
        default:
          break;
      }
    }
    if (orders.isEmpty) {
      return RouteStatus.toValidate;
    }

    final completedOrders =
        orders.where((order) => _isCompletedStatus(order.planningStatus)).length;

    if (completedOrders >= orders.length && orders.isNotEmpty) {
      return RouteStatus.finished;
    }
    return RouteStatus.toValidate;
  }

  /// Obtiene el color basado en el estado
  int getStatusColor() {
    return status.colorInt;
  }

  /// Retorna si hay órdenes completadas (no pendientes)
  bool get inProgress {
    if (stateRoute != null && stateRoute!.isNotEmpty) {
      return status == RouteStatus.inRoute;
    }
    final completedOrders =
        orders.where((order) => _isCompletedStatus(order.planningStatus)).length;
    return completedOrders > 0;
  }

  /// Calcula el progreso como fracción basado en órdenes completadas
  double get progressValue {
    if (ordersQty == 0) return 0;
    final completedOrders =
        orders.where((order) => _isCompletedStatus(order.planningStatus)).length;
    return completedOrders / ordersQty;
  }

  /// Formatea el texto de progreso
  String get progressText {
    final pendingCount =
        orders.where((order) => _isPendingStatus(order.planningStatus)).length;
    return 'Pendiente $pendingCount / $ordersQty órdenes';
  }

  /// Cuenta órdenes pendientes
  int get pendingOrdersCount =>
      orders.where((order) => _isPendingStatus(order.planningStatus)).length;

  int get statusCount {
    if (orders.isEmpty) {
      return 0;
    }
    return orders.where((order) => _isCompletedStatus(order.planningStatus)).length;
  }

  String get statusDisplay {
    if (stateRoute != null && stateRoute!.isNotEmpty) {
      return status.label;
    }
    final completedOrders =
        orders.where((order) => _isCompletedStatus(order.planningStatus)).length;
    return 'Terminado · $completedOrders/$ordersQty';
  }
}
