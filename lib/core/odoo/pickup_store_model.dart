/// Tienda de recogida asignada al conductor (modelo Odoo `trainyl.origin.stores`).
class PickupStore {
  final int id;
  final String name;
  final String address;
  final String client;
  final String sellerCode;

  /// Validación de formato del código (definida en el cliente, ej. Ripley)
  final bool scanValidate;
  final String scanPrefix;
  final int scanLength;

  /// Etiqueta combinada "Cliente Tienda" (ej. "Ripley SJL"). La usa el cargo.
  final String fullName;

  PickupStore({
    required this.id,
    required this.name,
    required this.address,
    this.client = '',
    this.sellerCode = '',
    this.scanValidate = false,
    this.scanPrefix = '',
    this.scanLength = 0,
    String? fullName,
  }) : fullName = (fullName == null || fullName.isEmpty)
            ? ((client.isEmpty ? name : '$client $name').trim())
            : fullName;

  factory PickupStore.fromJson(Map<String, dynamic> json) {
    return PickupStore(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      client: json['client'] as String? ?? '',
      sellerCode: json['seller_code'] as String? ?? '',
      scanValidate: json['scan_validate'] == true,
      scanPrefix: json['scan_prefix'] as String? ?? '',
      scanLength: (json['scan_length'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? '',
    );
  }
}

/// Resultado del endpoint de tiendas: incluye datos del conductor/vehículo
/// (placa) además de la lista de tiendas asignadas.
class PickupStoresResult {
  final String driverName;
  final String placa;
  final List<PickupStore> stores;

  PickupStoresResult({
    required this.driverName,
    required this.placa,
    required this.stores,
  });
}
