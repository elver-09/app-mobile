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

    final bg = MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.disabled)) return disabledColor;
      if (states.contains(MaterialState.pressed)) return pressedColor;
      return primaryColor;
    });

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          backgroundColor: bg,
          foregroundColor: MaterialStateProperty.all<Color?>(Colors.white),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 18)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
          elevation: MaterialStateProperty.resolveWith<double>((states) => states.contains(MaterialState.disabled) ? 0 : 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'REPROGRAMAR',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
