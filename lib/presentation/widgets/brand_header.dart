import 'package:flutter/material.dart';

/// Encabezado corporativo reutilizable: degradado azul limpio con borde
/// inferior curvo, un brillo "glossy" azul claro y sombra suave.
/// Se usa en el selector de modo, recojo en tienda y escáner de recojo.
///
/// El [child] debe incluir su propio padding (incluyendo el inset superior
/// del status bar) y dejar algo de espacio inferior para la curva.
class BrandHeader extends StatelessWidget {
  final Widget child;

  const BrandHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BrandHeaderPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _BrandHeaderPainter extends CustomPainter {
  // Paleta corporativa refinada (azules limpios, sin negro) — gradiente marcado
  static const _c1 = Color(0xFF4A90F2); // azul claro brillante
  static const _c2 = Color(0xFF245FB8); // azul medio
  static const _c3 = Color(0xFF143A7A); // navy marca (no negro)

  @override
  void paint(Canvas canvas, Size size) {
    const curve = 26.0;

    // Forma con borde inferior curvo (convexo y suave)
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height - curve)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + curve * 0.55,
        size.width,
        size.height - curve,
      )
      ..lineTo(size.width, 0)
      ..close();

    // Sombra suave bajo el encabezado
    canvas.drawShadow(path, const Color(0xFF0B2A5E), 10, false);

    // Relleno con degradado diagonal
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_c1, _c2, _c3],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, basePaint);

    canvas.save();
    canvas.clipPath(path);

    // Brillo "glossy" azul claro arriba a la derecha
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6FB0FF).withOpacity(0.30),
          const Color(0xFF6FB0FF).withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.10),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawRect(Offset.zero & size, glow);

    // Halo blanco tenue arriba a la izquierda (balance)
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.10),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.05, 0),
          radius: size.width * 0.45,
        ),
      );
    canvas.drawRect(Offset.zero & size, halo);

    // Línea de luz superior (acabado premium)
    final topLine = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(0, 0.5),
      Offset(size.width, 0.5),
      topLine,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
