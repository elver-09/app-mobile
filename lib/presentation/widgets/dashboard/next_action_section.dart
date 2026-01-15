import 'package:flutter/material.dart';

class NextActionSection extends StatelessWidget {
  final String routeName;
  final int orderCount;
  final double distanceKm;
  final String etaFirstDelivery;
  final VoidCallback? onStartRoute;

  const NextActionSection({
    super.key,
    required this.routeName,
    required this.orderCount,
    required this.distanceKm,
    required this.etaFirstDelivery,
    this.onStartRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timeline,
                    color: Colors.blue.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Próxima acción',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.send_rounded,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ir a ruta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            routeName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$orderCount órdenes · ${distanceKm.toStringAsFixed(0)} km · ETA primera entrega $etaFirstDelivery',
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
