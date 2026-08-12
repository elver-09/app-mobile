import 'package:flutter/material.dart';

class RouteCard extends StatelessWidget {
  final int routeId;
  final String routeName;
  final String title;
  final String status;
  final String? routeDate;
  final int stops;
  final int orders;
  final String progressText;
  final double progress;
  final Color statusColor;
  final bool inProgress;
  final VoidCallback onTapDetail;
  final bool isFinished;
  final VoidCallback onTerminar;

  const RouteCard({
    super.key,
    required this.routeId,
    required this.routeName,
    required this.title,
    required this.status,
    this.routeDate,
    required this.stops,
    required this.orders,
    required this.progressText,
    required this.progress,
    required this.statusColor,
    required this.inProgress,
    required this.onTapDetail,
    this.isFinished = false,
    required this.onTerminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (routeDate != null && routeDate!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRouteDate(),
          ],
          const SizedBox(height: 14),
          _buildStatsRow(),
          const SizedBox(height: 14),
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          status,
          style: TextStyle(
            fontSize: 13,
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildRouteDate() {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 15,
          color: Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Text(
          'Fecha de ruta: ${_formatRouteDate(routeDate!)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatRouteDate(String value) {
    final cleanValue = value.trim();
    final parsed = DateTime.tryParse(cleanValue);
    if (parsed == null) return cleanValue;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 17,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              '$stops paradas',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            const Icon(
              Icons.inventory_2,
              size: 17,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              '$orders órdenes',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            minHeight: 8,
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
        Expanded(
          child: Text(
            progressText,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (isFinished) ...[
          GestureDetector(
            onTap: onTerminar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F7EF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFA7E3C8),
                  width: 1,
                ),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.check_circle_outline,
                    size: 13,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Terminar',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: onTapDetail,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFBFDBFE),
                width: 1,
              ),
            ),
            child: Row(
              children: const [
                Text(
                  'Ver detalle',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 11,
                  color: Color(0xFF2563EB),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
