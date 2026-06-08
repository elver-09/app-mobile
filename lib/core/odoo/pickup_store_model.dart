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
