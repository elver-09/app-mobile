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

  /// Calcula el estado de la ruta
  String getStatus() {
    if (delivered == planned) return 'Terminado';
    if (confirmed > 0 || delivered > 0) return 'En progreso';
    return 'Pendiente';
  }

  /// Obtiene el color basado en el estado
  int getStatusColor() {
    if (delivered == planned) return 0xFF059669; // Verde
    if (confirmed > 0 || delivered > 0) return 0xFF2563EB; // Azul
    return 0xFF9CA3AF; // Gris
  }

  /// Retorna si está en progreso
  bool get inProgress => delivered > 0 || confirmed > 0;

  /// Calcula el progreso como fracción
  double get progressValue {
    if (ordersQty == 0) return 0;
    return delivered / ordersQty;
  }

  /// Formatea el texto de progreso
  String get progressText => 'Progreso $delivered / $ordersQty entregas';

  /// Formatea el estado con número
  // Primer número depende del estado de la orden:
  // - Terminado: entregadas (delivered)
  // - En progreso: confirmadas (confirmed)
  // - Pendiente: 0
  int get statusCount {
    final s = getStatus();
    if (s == 'Terminado') return delivered;
    if (s == 'En progreso') return confirmed;
    return 0;
  }

  String get statusDisplay => '${getStatus()} · $statusCount/$ordersQty';
}
