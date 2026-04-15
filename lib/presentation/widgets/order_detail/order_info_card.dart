import 'package:flutter/material.dart';

class OrderInfoCard extends StatelessWidget {
  final int? routeSequence;
  final String orderNumber;
  final String clientName;
  final String phone;
  final String address;
  final String district;
  final String? product;
  final VoidCallback onCallPressed;
  final VoidCallback onMapPressed;
  final String statusLabel;
  final Color statusColor;
  final bool isBlocked;
  final bool showRibbon;
  final bool isMultipack;
  final int expectedPackages;
  final int scannedPackages;
  final int remainingPackages;

  const OrderInfoCard({
    super.key,
    this.routeSequence,
    required this.orderNumber,
    required this.clientName,
    required this.phone,
    required this.address,
    required this.district,
    this.product,
    required this.onCallPressed,
    required this.onMapPressed,
    this.statusLabel = 'Pendiente',
    this.statusColor = const Color(0xFF2563EB),
    this.isBlocked = false,
    this.showRibbon = true,
    this.isMultipack = false,
    this.expectedPackages = 1,
    this.scannedPackages = 0,
    this.remainingPackages = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: isBlocked ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: AbsorbPointer(
              absorbing: isBlocked,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (routeSequence != null && routeSequence! > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF93C5FD),
                                  ),
                                ),
                                child: Text(
                                  '# $routeSequence',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                orderNumber,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!showRibbon)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Zona $district',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Producto: ${product ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (isMultipack && expectedPackages > 1) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFFEA580C),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Multibulto: $scannedPackages/$expectedPackages escaneados · Faltan $remainingPackages',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9A3412),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildInfoRow('Cliente:', clientName),
                  const SizedBox(height: 8),
                  _buildInfoRow('Teléfono:', phone),
                  const SizedBox(height: 8),
                  _buildInfoRow('Dirección:', address),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.92,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onCallPressed,
                              icon: const Icon(Icons.phone, size: 14),
                              label: Text(
                                'Llamar a ${clientName.split(' ').first}',
                                style: const TextStyle(fontSize: 10.8),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                minimumSize: const Size(0, 34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onMapPressed,
                              icon: const Icon(Icons.map_outlined, size: 14),
                              label: const Text(
                                'Abrir en mapas',
                                style: TextStyle(fontSize: 10.8),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D4ED8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                minimumSize: const Size(0, 34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showRibbon)
          _buildStatusRibbon(
            label: statusLabel,
            baseColor: statusColor,
            isBlocked: isBlocked,
          ),
      ],
    );
  }

  Widget _buildStatusRibbon({
    required String label,
    required Color baseColor,
    required bool isBlocked,
  }) {
    final ribbonColor = baseColor.withOpacity(0.95);
    final colors = isBlocked
        ? const [Color(0xFF7C3AED), Color(0xFF8B5CF6)]
        : [ribbonColor, ribbonColor];

    return Positioned(
      top: 12,
      right: -48,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: 0.62,
          child: Container(
            width: 190,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
