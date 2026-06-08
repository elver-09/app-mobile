import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Camión de reparto animado, reconstruido a partir de `camion.svg`.
///
/// El SVG original trae animaciones SMIL que `flutter_svg` NO interpreta,
/// así que el gráfico se separó en dos capas (cuerpo + líneas de velocidad)
/// que comparten el mismo `viewBox` para que apilen con precisión, y el
/// movimiento se reproduce de forma nativa en Flutter:
///   • rebote vertical sutil de todo el camión (motor/marcha)
///   • líneas de velocidad que se desplazan y se desvanecen en bucle
///
/// Es totalmente autocontenido: no requiere registrar assets en pubspec.
class AnimatedTruck extends StatefulWidget {
  /// Ancho del camión en píxeles lógicos. La altura se calcula por proporción.
  final double width;

  /// Color del trazo (se reemplaza el azul original vía ColorFilter).
  final Color color;

  /// Amplitud del rebote vertical en px.
  final double bobAmplitude;

  /// Si se animan las líneas de velocidad.
  final bool windStream;

  /// Duración de un ciclo de rebote.
  final Duration bobDuration;

  const AnimatedTruck({
    super.key,
    this.width = 220,
    this.color = Colors.white,
    this.bobAmplitude = 4,
    this.windStream = true,
    this.bobDuration = const Duration(milliseconds: 1600),
  });

  /// Proporción ancho/alto del viewBox compartido (273 x 152).
  static const double aspect = 273 / 152;

  @override
  State<AnimatedTruck> createState() => _AnimatedTruckState();
}

class _AnimatedTruckState extends State<AnimatedTruck>
    with TickerProviderStateMixin {
  late final AnimationController _bobCtrl;
  late final AnimationController _windCtrl;

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(vsync: this, duration: widget.bobDuration)
      ..repeat(reverse: true);
    _windCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _bobCtrl.dispose();
    _windCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w / AnimatedTruck.aspect;
    final filter = ColorFilter.mode(widget.color, BlendMode.srcIn);

    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bobCtrl, _windCtrl]),
        builder: (_, __) {
          final bobY =
              math.sin(_bobCtrl.value * math.pi) * widget.bobAmplitude;

          return Transform.translate(
            offset: Offset(0, bobY),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Líneas de velocidad (dos copias desfasadas) ───────────
                if (widget.windStream) ..._buildWind(w, h, filter),

                // ── Cuerpo del camión ─────────────────────────────────────
                Positioned.fill(
                  child: SvgPicture.string(
                    _kTruckSvg,
                    fit: BoxFit.contain,
                    colorFilter: filter,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildWind(double w, double h, ColorFilter filter) {
    // Dos copias con fase 0 y 0.5 → flujo continuo de líneas que "salen
    // disparadas" hacia atrás y se desvanecen, sugiriendo velocidad.
    return [0.0, 0.5].map((phase) {
      final t = (_windCtrl.value + phase) % 1.0;
      final dx = -t * w * 0.16;
      final opacity = math.sin(t * math.pi) * 0.9; // 0→1→0
      return Positioned.fill(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: SvgPicture.string(
              _kWindSvg,
              fit: BoxFit.contain,
              colorFilter: filter,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Capas SVG incrustadas (mismo viewBox "119 200 273 152" → apilan exactas)
// ═══════════════════════════════════════════════════════════════════════════

const String _kTruckSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="119 200 273 152"><g transform="matrix(0.58,0,0,0.58,267.186,267.961)" id="road"><g id="Shape 1"><path stroke-linejoin="round" stroke-linecap="round" stroke-width="15" stroke-opacity="1" stroke="#2875cb" d="M-175,115L184,115" /></g></g><g id="box"><g transform="translate(267.186,266.221)"><g transform="scale(0.58,0.58) translate(0,0)"><g id="Rectangle 1" transform="matrix(1,0,0,1,-43.212,-14.533)"><path stroke-linejoin="round" stroke-linecap="round" stroke-width="15" stroke-opacity="1" stroke="#2875cb" d="M82.788,-57L82.788,57.934C82.788,64.009,77.863,68.934,71.788,68.934L-67.538,68.967C-73.613,68.967,-78.538,64.042,-78.538,57.967L-78.538,-56.967C-78.538,-63.042,-73.613,-67.967,-67.538,-67.967L71.788,-68C77.863,-68,82.788,-63.075,82.788,-57Z" /></g></g></g></g><g id="chassis"><g transform="translate(267.186,260.593)"><g transform="scale(0.58,0.58) translate(0,0)"><g transform="matrix(1,0,0,1,0,0)" id="head"><g id="Rectangle 1" transform="matrix(1,0,0,1,120.116,13.237)"><path stroke-linejoin="round" stroke-linecap="round" stroke-width="15" stroke-opacity="1" stroke="#2875cb" d="M55.616,3.763L55.616,53.237C55.616,58.208,51.587,62.237,46.616,62.237L-48.116,62.237C-53.087,62.237,-57.116,58.208,-57.116,53.237L-57.116,-54.487C-57.116,-59.458,-53.087,-63.487,-48.116,-63.487L-4.616,-63.487L55.616,3.763Z" /></g></g></g></g></g><g id="chassis"><g transform="translate(267.186,260.593)"><g transform="scale(0.58,0.58) translate(0,0)"><g id="Shape 1"><path stroke-linejoin="miter" stroke-linecap="round" stroke-width="15" stroke-opacity="1" stroke="#2875cb" d="M-112.5,76.75L92.5,76.75" /></g></g></g></g><g id="chassis"><g transform="translate(267.186,260.593)"><g transform="scale(0.58,0.58) translate(0,0)"><g transform="matrix(1,0,0,1,0,0)" id="glass"><g id="Shape 1"><path stroke-linejoin="round" stroke-linecap="butt" stroke-width="15" stroke-opacity="1" stroke="#2875cb" d="M98,-50L98,13L171.5,13" /></g></g></g></g></g><g transform="matrix(0.58,0,0,0.58,266.606,266.221)" id="wheels_rr"><g id="Ellipse 1" transform="matrix(1,0,0,1,-42.08,87.189)"><ellipse ry="25" rx="25" cy="0" cx="0" stroke-linejoin="miter" stroke-linecap="butt" stroke-width="15" stroke-opacity="1" stroke="#2875cb" /></g></g><g transform="matrix(0.58,0,0,0.58,364.046,266.221)" id="wheels_fr"><g id="Ellipse 1" transform="matrix(1,0,0,1,-42.08,87.189)"><ellipse ry="25" rx="25" cy="0" cx="0" stroke-linejoin="miter" stroke-linecap="butt" stroke-width="15" stroke-opacity="1" stroke="#2875cb" /></g></g><g id="wheels_in_fr"><g transform="translate(339.64,316.791)"><g transform="rotate(0)"><g transform="scale(0.58,0.58) translate(42.08,-87.189)"><g id="Ellipse 1" transform="matrix(1,0,0,1,-42.08,87.189)"><ellipse ry="12.5" rx="12.5" cy="0" cx="0" stroke-linejoin="miter" stroke-linecap="butt" stroke-width="3" stroke-opacity="1" stroke="#2875cb" /></g></g></g></g></g><g id="wheels_in_rr"><g transform="translate(242.2,316.791)"><g transform="rotate(166.667)"><g transform="scale(0.58,0.58) translate(42.08,-87.189)"><g id="Ellipse 1" transform="matrix(1,0,0,1,-42.08,87.189)"><ellipse ry="12.5" rx="12.5" cy="0" cx="0" stroke-linejoin="miter" stroke-linecap="butt" stroke-width="3" stroke-opacity="1" stroke="#2875cb" /></g></g></g></g></g></svg>
''';

const String _kWindSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="119 200 273 152"><g id="box"><g transform="translate(267.186,266.221)"><g transform="scale(0.58,0.58) translate(0,0)"><g transform="matrix(1,0,0,1,0,0)" id="Eind_blow2"><g id="Shape 1"><path stroke-linejoin="round" stroke-linecap="round" stroke-width="15" stroke-opacity="1" stroke="#2875cb" d="M-185,-46L-63,-46" /></g></g></g></g></g><g id="box"><g transform="translate(267.186,266.221)"><g transform="scale(0.58,0.58) translate(0,0)"><g transform="matrix(1,0,0,1,-37.735,25.862)" id="wind_blow"><g id="Shape 1"><path stroke-linejoin="round" stroke-linecap="round" stroke-width="15" stroke-opacity="1" stroke="#2875cb" d="M-185,-46L-63,-46" /></g></g></g></g></g></svg>
''';
