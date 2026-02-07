import 'package:flutter/material.dart';

class DeliveryStatusButtons extends StatelessWidget {
  final VoidCallback onEntregadoPressed;
  final VoidCallback onRechazadoPressed;

  const DeliveryStatusButtons({
    super.key,
    required this.onEntregadoPressed,
    required this.onRechazadoPressed,
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
    return Row(
      children: [
        _buildStatusButton(
          label: 'Entregado',
          icon: Icons.check_circle_outline,
          backgroundColor: const Color(0xFF0F766E),
          onPressed: onEntregadoPressed,
        ),
        const SizedBox(width: 12),
        _buildStatusButton(
          label: 'Rechazado',
          icon: Icons.cancel_outlined,
          backgroundColor: const Color(0xFFB91C1C),
          onPressed: onRechazadoPressed,
        ),
      ],
    );
  }
}
