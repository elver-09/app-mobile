import 'package:flutter/material.dart';

class StatisticsSection extends StatelessWidget {
  final int assigned;
  final int scanned;
  final int delivered;
  final int pending;

  const StatisticsSection({
    super.key,
    required this.assigned,
    required this.scanned,
    required this.delivered,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Assigned and Scanned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatistic(
                'Asignadas hoy',
                assigned.toString(),
                Colors.black,
              ),
              _buildStatistic(
                'Escaneadas',
                scanned.toString(),
                const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Second row: Delivered and Pending
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatistic(
                'Entregadas',
                delivered.toString(),
                const Color(0xFF059669),
              ),
              _buildStatistic(
                'Pendientes',
                pending.toString(),
                const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistic(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
