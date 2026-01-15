import 'package:flutter/material.dart';

class RouteCard extends StatelessWidget {
  final int routeId;
  final String routeName;
  final String title;
  final String status;
  final int stops;
  final int orders;
  final String progressText;
  final double progress;
  final Color statusColor;
  final bool inProgress;
  final VoidCallback onTapDetail;

  const RouteCard({
    super.key,
    required this.routeId,
    required this.routeName,
    required this.title,
    required this.status,
    required this.stops,
    required this.orders,
    required this.progressText,
    required this.progress,
    required this.statusColor,
    required this.inProgress,
    required this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildStatsRow(),
          const SizedBox(height: 12),
          if (inProgress) _buildProgressBar(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                inProgress ? Icons.play_circle_outline : Icons.pause_circle_outline,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '$stops paradas',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '$orders órdenes',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          progressText,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        GestureDetector(
          onTap: onTapDetail,
          child: Row(
            children: const [
              Text(
                'Ver detalle',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
