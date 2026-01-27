import 'package:flutter/material.dart';

class DeliveryStatusButtons extends StatelessWidget {
  final VoidCallback onEntregadoPressed;
  final VoidCallback onRechazadoPressed;
  final VoidCallback onAnuladoPressed;
  final VoidCallback onSiniestradoPressed;

  const DeliveryStatusButtons({
    super.key,
    required this.onEntregadoPressed,
    required this.onRechazadoPressed,
    required this.onAnuladoPressed,
    required this.onSiniestradoPressed,
  });

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          print('🔘 Botón presionado: $label');
          onPressed();
        },
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primera fila: ENTREGADO y RECHAZADO
        Row(
          children: [
            _buildStatusButton(
              label: 'Entregado',
              icon: Icons.check_circle_outline,
              backgroundColor: const Color(0xFF10B981),
              onPressed: onEntregadoPressed,
            ),
            const SizedBox(width: 12),
            _buildStatusButton(
              label: 'Rechazado',
              icon: Icons.cancel_outlined,
              backgroundColor: const Color(0xFFEF4444),
              onPressed: onRechazadoPressed,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segunda fila: ANULADO y SINIESTRADO
        Row(
          children: [
            _buildStatusButton(
              label: 'Anulado',
              icon: Icons.block,
              backgroundColor: const Color(0xFFF97316),
              onPressed: onAnuladoPressed,
            ),
            const SizedBox(width: 12),
            _buildStatusButton(
              label: 'Siniestrado',
              icon: Icons.warning_outlined,
              backgroundColor: const Color(0xFF6366F1),
              onPressed: onSiniestradoPressed,
            ),
          ],
        ),
      ],
    );
  }
}
