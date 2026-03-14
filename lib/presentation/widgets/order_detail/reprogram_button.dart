import 'package:flutter/material.dart';

class ReprogramButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool enabled;
  final bool visible;

  const ReprogramButton({Key? key, this.onPressed, this.enabled = true, this.visible = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si no es visible, retornar widget vacío
    if (!visible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    // Opción C - Gris elegante
    const primaryColor = Color(0xFF374151); // fondo
    const pressedColor = Color(0xFF1F2937);
    const disabledColor = Color(0xFFCBD5E1);

    final bg = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) return disabledColor;
      if (states.contains(WidgetState.pressed)) return pressedColor;
      return primaryColor;
    });

    return Center(
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          backgroundColor: bg,
          foregroundColor: WidgetStateProperty.all<Color?>(Colors.white),
          minimumSize: WidgetStateProperty.all(Size.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 9, horizontal: 12)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          elevation: WidgetStateProperty.resolveWith<double>((states) => states.contains(WidgetState.disabled) ? 0 : 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'REPROGRAMAR',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
