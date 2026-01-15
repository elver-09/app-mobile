import 'package:flutter/material.dart';

class DeliveryStatusButtons extends StatelessWidget {
  final VoidCallback onSuccessPressed;
  final VoidCallback onFailedPressed;

  const DeliveryStatusButtons({
    super.key,
    required this.onSuccessPressed,
    required this.onFailedPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSuccessPressed,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Entrega exitosa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
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
            onPressed: onFailedPressed,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Entrega fallida'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
