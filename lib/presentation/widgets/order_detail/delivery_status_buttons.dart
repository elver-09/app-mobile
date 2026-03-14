import 'package:flutter/material.dart';

class DeliveryStatusButtons extends StatelessWidget {
  final VoidCallback onEntregadoPressed;
  final VoidCallback onRechazadoPressed;
  final bool isOrderInProgress;
  final String currentStatus;

  const DeliveryStatusButtons({
    super.key,
    required this.onEntregadoPressed,
    required this.onRechazadoPressed,
    this.isOrderInProgress = true,
    this.currentStatus = '',
  });

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: isOrderInProgress ? () {
          print('🔘 Botón presionado: $label');
          onPressed();
        } : null,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          elevation: 0,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determinar el mensaje apropiado
    String message = '';
    Color backgroundColor = const Color(0xFFFEF3C7);
    Color borderColor = const Color(0xFFFCD34D);
    Color iconColor = const Color(0xFFF59E0B);
    Color textColor = const Color(0xFF92400E);
    
    if (currentStatus == 'delivered') {
      message = 'Esta orden ya fue entregada';
      backgroundColor = const Color(0xFFD1FAE5);
      borderColor = const Color(0xFF6EE7B7);
      iconColor = const Color(0xFF059669);
      textColor = const Color(0xFF065F46);
    } else if (currentStatus == 'cancelled') {
      message = 'Esta orden ya fue rechazada';
      backgroundColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFFCA5A5);
      iconColor = const Color(0xFFDC2626);
      textColor = const Color(0xFF991B1B);
    } else if (!isOrderInProgress) {
      message = 'Debes iniciar esta orden para poder entregarla o rechazarla';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isOrderInProgress) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentStatus == 'delivered' || currentStatus == 'cancelled'
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: iconColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.center,
          child: FractionallySizedBox(
            widthFactor: 0.92,
            child: Row(
              children: [
                _buildStatusButton(
                  label: 'Entregado',
                  icon: Icons.check_circle_outline,
                  backgroundColor: const Color(0xFF0F766E),
                  onPressed: onEntregadoPressed,
                ),
                const SizedBox(width: 8),
                _buildStatusButton(
                  label: 'Rechazado',
                  icon: Icons.cancel_outlined,
                  backgroundColor: const Color(0xFFB91C1C),
                  onPressed: onRechazadoPressed,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
