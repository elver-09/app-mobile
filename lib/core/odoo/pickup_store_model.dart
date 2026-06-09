/// Tienda de recogida asignada al conductor (modelo Odoo `trainyl.origin.stores`).
class PickupStore {
  final int id;
  final String name;
  final String address;

  PickupStore({
    required this.id,
    required this.name,
    required this.address,
  });

  factory PickupStore.fromJson(Map<String, dynamic> json) {
    return PickupStore(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}

/// Resultado del endpoint de tiendas: incluye datos del conductor/vehículo
/// (placa) además de la lista de tiendas asignadas.
class PickupStoresResult {
  final String driverName;
  final String placa;
  final String vehicle;
  final List<PickupStore> stores;

  PickupStoresResult({
    required this.driverName,
    required this.placa,
    required this.vehicle,
    required this.stores,
  });
}
