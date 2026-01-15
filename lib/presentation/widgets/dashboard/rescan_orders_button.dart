import 'package:flutter/material.dart';

class RescanOrdersButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RescanOrdersButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.crop_free,
              color: Colors.green.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Reescanear órdenes de salida',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
