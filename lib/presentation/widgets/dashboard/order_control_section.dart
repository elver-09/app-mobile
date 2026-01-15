import 'package:flutter/material.dart';

class OrderControlSection extends StatelessWidget {
  const OrderControlSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control de órdenes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Escaneadas = Asignadas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: const [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Validado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Si agregas o retiras bultos, deberás volver a escanear para mantener el conteo correcto.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
