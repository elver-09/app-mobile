import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/app_routes.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Paleta de marca ──────────────────────────────────────────────────────
  static const Color kBlue       = Color(0xFF123C80);
  static const Color kBlueMid    = Color(0xFF0D2D61);
  static const Color kBlueDark   = Color(0xFF091E42);

  // ── Fase 1: degradado de fondo aparece ──────────────────────────────────
  late AnimationController _bgCtrl;
  late Animation<double>   _bgFade;

  // ── Fase 2: camión corre de izquierda a derecha y desaparece ─────────────
  late AnimationController _truckCtrl;
  late AnimationController _bounceCtrl;  // rebote de ruedas (repeat)
  late Animation<double>   _truckX;      // posición horizontal 0..1
  late Animation<double>   _truckFade;   // aparece y desaparece
  late Animation<double>   _truckBounce; // pequeño rebote vertical
  late Animation<double>   _dustFade;    // nube de polvo al salir

  // ── Fase 3: logo entra ───────────────────────────────────────────────────
  late AnimationController _logoCtrl;
  late Animation<double>   _logoScale;
  late Animation<double>   _logoFade;
  late Animation<double>   _subtitleFade;

  // ── Fase 4: botón entra ──────────────────────────────────────────────────
  late AnimationController _btnCtrl;
  late AnimationController _pulseCtrl; // pulso del botón (repeat)
  late Animation<double>   _btnSlide;
  late Animation<double>   _btnFade;
  late Animation<double>   _btnPulse;

  // ── Shimmer del botón ────────────────────────────────────────────────────
  late AnimationController _shimCtrl;

  bool _showBg    = false;
  bool _showTruck = false;
  bool _showLogo  = false;
  bool _showBtn   = false;

  @override
  void initState() {
    super.initState();
    _setup();
    _run();
  }

  void _setup() {
    // Fondo
    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    // Camión
    _truckCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800));
    _truckX = Tween<double>(begin: -0.2, end: 1.3).animate(
        CurvedAnimation(parent: _truckCtrl,
            curve: const Interval(0.0, 0.85, curve: Curves.easeInOut)));
    _truckFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 72),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_truckCtrl);
    _bounceCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300))
      ..repeat();
    _truckBounce = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -4.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: -4.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50),
    ]).animate(_bounceCtrl);
    // rebote simple usando el propio truckCtrl
    _dustFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _truckCtrl,
          curve: const Interval(0.70, 0.95, curve: Curves.easeOut)));

    // Logo
    _logoCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn)));

    // Botón
    _btnCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _btnSlide = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _btnCtrl,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut)));
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _btnCtrl,
            curve: const Interval(0.0, 0.7, curve: Curves.easeIn)));
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat();
    _btnPulse = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.04)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.04, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_pulseCtrl);

    // Shimmer
    _shimCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  Future<void> _run() async {
    // Mostrar fondo degradado
    setState(() => _showBg = true);
    await _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Mostrar camión corriendo
    setState(() => _showTruck = true);
    await _truckCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Mostrar logo
    setState(() { _showTruck = false; _showLogo = true; });
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Mostrar botón
    setState(() => _showBtn = true);
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _truckCtrl.dispose();
    _bounceCtrl.dispose();
    _logoCtrl.dispose();
    _btnCtrl.dispose();
    _pulseCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() =>
      Navigator.pushReplacementNamed(context, AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgFade,
        builder: (_, child) => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kBlue,
                kBlueMid,
                kBlueDark,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Círculos decorativos de fondo ──────────────────────────
            ..._buildBgCircles(size),

            // ── Línea de carretera ──────────────────────────────────────
            Positioned(
              bottom: size.height * 0.32,
              left: 0,
              right: 0,
              child: _RoadLine(),
            ),

            // ── Camión animado ─────────────────────────────────────────
            if (_showTruck)
              AnimatedBuilder(
                animation: _truckCtrl,
                builder: (_, __) {
                  final xPos = _truckX.value * size.width;
                  final yPos = size.height * 0.30;
                  return Positioned(
                    left: xPos - 70,
                    top: yPos,
                    child: Opacity(
                      opacity: _truckFade.value.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 70,
                            child: CustomPaint(
                              painter: _TruckPainter(
                                color: Colors.white,
                                progress: _truckCtrl.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // ── Nube de polvo al salir el camión ──────────────────────
            if (_showTruck)
              AnimatedBuilder(
                animation: _dustFade,
                builder: (_, __) {
                  if (_dustFade.value < 0.01) return const SizedBox.shrink();
                  return Positioned(
                    right: 20,
                    top: size.height * 0.30 + 40,
                    child: Opacity(
                      opacity: _dustFade.value * 0.6,
                      child: _DustCloud(),
                    ),
                  );
                },
              ),

            // ── Logo + subtítulo ───────────────────────────────────────
            if (_showLogo)
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_logoFade, _logoScale, _subtitleFade]),
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CustomPaint(
                              painter: _TrainylLogoPainter(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'TRAINYL',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FadeTransition(
                            opacity: _subtitleFade,
                            child: Text(
                              'logística de confianza',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withOpacity(0.75),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Botón Iniciar mi Jornada ──────────────────────────────
            if (_showBtn)
              Positioned(
                bottom: size.height * 0.10,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_btnFade, _btnSlide]),
                  builder: (_, child) => Opacity(
                    opacity: _btnFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _btnSlide.value),
                      child: child,
                    ),
                  ),
                  child: _JourneyButton(
                    onTap: _goToLogin,
                    shimCtrl: _shimCtrl,
                    pulseCtrl: _pulseCtrl,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBgCircles(Size size) {
    return [
      Positioned(
        top: -size.width * 0.3,
        right: -size.width * 0.2,
        child: Container(
          width: size.width * 0.8,
          height: size.width * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.04),
          ),
        ),
      ),
      Positioned(
        bottom: -size.width * 0.25,
        left: -size.width * 0.15,
        child: Container(
          width: size.width * 0.65,
          height: size.width * 0.65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      Positioned(
        top: size.height * 0.15,
        left: -30,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.035),
          ),
        ),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Línea de carretera animada
// ═══════════════════════════════════════════════════════════════════════════

class _RoadLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Nube de polvo
// ═══════════════════════════════════════════════════════════════════════════

class _DustCloud extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 40),
      painter: _DustPainter(),
    );
  }
}

class _DustPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.5), 14, paint);
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.4), 10, paint);
    paint.color = Colors.white.withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.6), 8, paint);
  }

  @override
  bool shouldRepaint(_DustPainter o) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter del camión
// ═══════════════════════════════════════════════════════════════════════════

class _TruckPainter extends CustomPainter {
  final Color color;
  final double progress; // 0..1 para animar ruedas

  _TruckPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wheelAngle = progress * math.pi * 8; // ruedas girando

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final darkPaint = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final accentPaint = Paint()
      ..color = color.withOpacity(0.30)
      ..style = PaintingStyle.fill;

    // ── Remolque ─────────────────────────────────────────────────────────
    final trailerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.0, h * 0.18, w * 0.58, h * 0.50),
      const Radius.circular(4),
    );
    canvas.drawRRect(trailerRect, bodyPaint);

    // Líneas del remolque
    for (int i = 1; i <= 3; i++) {
      final x = w * 0.0 + (w * 0.58 / 4) * i;
      canvas.drawLine(
        Offset(x, h * 0.18),
        Offset(x, h * 0.68),
        darkPaint..strokeWidth = 1.5,
      );
    }

    // ── Cabina del camión ─────────────────────────────────────────────────
    final cabinPath = Path()
      ..moveTo(w * 0.60, h * 0.68)
      ..lineTo(w * 0.60, h * 0.30)
      ..quadraticBezierTo(w * 0.62, h * 0.18, w * 0.72, h * 0.18)
      ..lineTo(w * 0.84, h * 0.18)
      ..quadraticBezierTo(w * 0.95, h * 0.20, w * 1.00, h * 0.34)
      ..lineTo(w * 1.00, h * 0.68)
      ..close();
    canvas.drawPath(cabinPath, bodyPaint);

    // ── Ventana de cabina ─────────────────────────────────────────────────
    final windowPath = Path()
      ..moveTo(w * 0.63, h * 0.28)
      ..lineTo(w * 0.63, h * 0.22)
      ..quadraticBezierTo(w * 0.64, h * 0.18, w * 0.72, h * 0.18)
      ..lineTo(w * 0.82, h * 0.18)
      ..quadraticBezierTo(w * 0.90, h * 0.19, w * 0.94, h * 0.28)
      ..close();
    canvas.drawPath(windowPath, accentPaint);

    // ── Parrilla frontal ──────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(w * 0.93, h * 0.42, w * 0.07, h * 0.22),
      darkPaint..color = color.withOpacity(0.40),
    );
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w * 0.93, h * 0.42 + (h * 0.22 / 3) * i + h * 0.04),
        Offset(w * 1.00, h * 0.42 + (h * 0.22 / 3) * i + h * 0.04),
        darkPaint
          ..color = color.withOpacity(0.35)
          ..strokeWidth = 1.0,
      );
    }

    // ── Ruedas (con rotación) ─────────────────────────────────────────────
    _drawWheel(canvas, Offset(w * 0.13, h * 0.72), h * 0.15, wheelAngle, bodyPaint, darkPaint, accentPaint);
    _drawWheel(canvas, Offset(w * 0.42, h * 0.72), h * 0.15, wheelAngle, bodyPaint, darkPaint, accentPaint);
    _drawWheel(canvas, Offset(w * 0.82, h * 0.72), h * 0.17, wheelAngle, bodyPaint, darkPaint, accentPaint);

    // ── Línea de suelo debajo del camión ──────────────────────────────────
    canvas.drawLine(
      Offset(0, h * 0.87),
      Offset(w, h * 0.87),
      strokePaint
        ..color = color.withOpacity(0.25)
        ..strokeWidth = 1.0,
    );

    // ── Luz delantera ─────────────────────────────────────────────────────
    final headlightPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.975, h * 0.34, w * 0.025, h * 0.10),
      headlightPaint,
    );
  }

  void _drawWheel(Canvas canvas, Offset center, double r,
      double angle, Paint body, Paint dark, Paint accent) {
    // Llanta
    final tirePaint = Paint()
      ..color = body.color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, tirePaint);

    // Aro interior
    final rimPaint = Paint()
      ..color = body.color.withOpacity(0.40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.6, rimPaint);

    // Radios giratorios
    final spokePaint = Paint()
      ..color = body.color.withOpacity(0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final spokeAngle = angle + (math.pi / 3) * i;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(spokeAngle) * r * 0.55,
               center.dy + math.sin(spokeAngle) * r * 0.55),
        spokePaint,
      );
    }

    // Centro
    canvas.drawCircle(center, r * 0.18, body);
  }

  @override
  bool shouldRepaint(_TruckPainter o) =>
      o.color != color || o.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// Botón "Iniciar mi Jornada" — interactivo con pulso
// ═══════════════════════════════════════════════════════════════════════════

class _JourneyButton extends StatefulWidget {
  final VoidCallback onTap;
  final AnimationController shimCtrl;
  final AnimationController pulseCtrl;
  const _JourneyButton({required this.onTap, required this.shimCtrl, required this.pulseCtrl});

  @override
  State<_JourneyButton> createState() => _JourneyButtonState();
}

class _JourneyButtonState extends State<_JourneyButton> {
  static const Color kBlue    = Color(0xFF123C80);
  static const Color kBlueMid = Color(0xFF0D2D61);

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: widget.pulseCtrl,
        builder: (_, child) {
          final pulse = Tween<double>(begin: 1.0, end: 1.05)
              .chain(CurveTween(curve: Curves.easeInOut))
              .evaluate(widget.pulseCtrl);
          return Transform.scale(
            scale: _pressed ? 0.95 : pulse,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 260,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: _pressed
                  ? [kBlueMid, kBlue]
                  : [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.70),
              width: 1.8,
            ),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: widget.shimCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ShimmerPainter(progress: widget.shimCtrl.value),
                    size: const Size(260, 58),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Iniciar mi Jornada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shimmer Painter
// ═══════════════════════════════════════════════════════════════════════════

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * (progress * 1.6 - 0.3);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, Colors.white.withOpacity(0.20), Colors.transparent],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(x - 60, 0, 120, size.height));
    final path = Path()
      ..moveTo(x - 45, 0)..lineTo(x + 15, 0)
      ..lineTo(x - 5, size.height)..lineTo(x - 65, size.height)..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter o) => o.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter: logo Trainyl — hexágono con cubo isométrico
// ═══════════════════════════════════════════════════════════════════════════

class _TrainylLogoPainter extends CustomPainter {
  final Color color;
  _TrainylLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final sw = w * 0.055;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Hexágono exterior (flat-top, lados redondeados) ─────────────────
    final hexR   = w * 0.46;
    final corner = w * 0.08;
    canvas.drawPath(_roundedHexPath(cx, cy, hexR, corner), stroke);

    // ── Cubo isométrico interior ────────────────────────────────────────
    // El cubo se dibuja como 3 rombos (cara top, cara izquierda, cara derecha)
    // usando solo stroke (igual que el hexágono exterior).
    final cr = w * 0.22; // radio del cubo inscrito
    // Perspectiva isométrica: eje Y comprimido al 60%
    const double iso = 0.58;

    // Los 7 vértices del cubo isométrico:
    //   top    = arriba
    //   left   = izq
    //   right  = der
    //   bottom = abajo
    //   tl, tr = top-left, top-right
    //   bl, br = bot-left, bot-right (no se usan todos)

    final top    = Offset(cx,         cy - cr * iso);
    final left   = Offset(cx - cr,    cy);
    final right  = Offset(cx + cr,    cy);
    final bottom = Offset(cx,         cy + cr * iso);
    final tl     = Offset(cx - cr,    cy - cr * iso);
    final tr     = Offset(cx + cr,    cy - cr * iso);
    final bl     = Offset(cx - cr,    cy + cr * iso);
    final br     = Offset(cx + cr,    cy + cr * iso);

    // cara superior (rombo: tl → top → tr → center)
    final topFace = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(top.dx, top.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(topFace, stroke);

    // cara izquierda (rombo: tl → left → bottom → center)
    final leftFace = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(bl.dx, bl.dy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(leftFace, stroke);

    // cara derecha (rombo: tr → right → br → center)
    final rightFace = Path()
      ..moveTo(tr.dx, tr.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(rightFace, stroke);

    // líneas verticales de las aristas del cubo (refuerza la forma 3D)
    canvas.drawLine(Offset(cx, cy), bottom, stroke);
  }

  Path _roundedHexPath(double cx, double cy, double r, double radius) {
    final vertices = List.generate(6, (i) {
      final angle = math.pi / 180 * (60 * i - 30);
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    });

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final prev = vertices[(i + 5) % 6];
      final curr = vertices[i];
      final next = vertices[(i + 1) % 6];

      final toPrev = (prev - curr);
      final toNext = (next - curr);
      final lenPrev = toPrev.distance;
      final lenNext = toNext.distance;
      final r1 = math.min(radius, lenPrev / 2);
      final r2 = math.min(radius, lenNext / 2);

      final p1 = curr + Offset(toPrev.dx / lenPrev * r1, toPrev.dy / lenPrev * r1);
      final p2 = curr + Offset(toNext.dx / lenNext * r2, toNext.dy / lenNext * r2);

      if (i == 0) path.moveTo(p1.dx, p1.dy); else path.lineTo(p1.dx, p1.dy);
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_TrainylLogoPainter o) => o.color != color;
}
