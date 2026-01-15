import 'package:flutter/material.dart';

class OrderInfoCard extends StatelessWidget {
  final String orderNumber;
  final String clientName;
  final String phone;
  final String address;
  final String reference;
  final String district;
  final VoidCallback onCallPressed;
  final VoidCallback onMapPressed;

  const OrderInfoCard({
    super.key,
    required this.orderNumber,
    required this.clientName,
    required this.phone,
    required this.address,
    required this.reference,
    required this.district,
    required this.onCallPressed,
    required this.onMapPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderNumber,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'En curso',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            clientName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Producto: Despensa semanal · Zona $district',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Cliente:', clientName),
          const SizedBox(height: 12),
          _buildInfoRow('Teléfono:', phone),
          const SizedBox(height: 12),
          _buildInfoRow('Dirección:', address),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Referencia:',
            reference.isNotEmpty ? reference : address,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCallPressed,
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text('Llamar a ${clientName.split(' ').first}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F2FE),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onMapPressed,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Abrir en mapas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F2FE),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
