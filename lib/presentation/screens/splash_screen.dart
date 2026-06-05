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

  // ── Paleta ───────────────────────────────────────────────────────────────
  static const kBlue      = Color(0xFF123C80);
  static const kBlueMid   = Color(0xFF0D2D61);
  static const kBlueDark  = Color(0xFF071428);
  static const kAccent    = Color(0xFF1A5BB5);
  static const kGlow      = Color(0xFF2176D2);

  // ── Controllers ─────────────────────────────────────────────────────────
  late AnimationController _bgCtrl;      // fondo
  late AnimationController _orb1Ctrl;    // orbe flotante 1
  late AnimationController _orb2Ctrl;    // orbe flotante 2
  late AnimationController _scanCtrl;    // línea de scan
  late AnimationController _truckCtrl;   // camión
  late AnimationController _bounceCtrl;  // rebote ruedas
  late AnimationController _logoCtrl;    // logo entra
  late AnimationController _glowCtrl;    // brillo logo
  late AnimationController _btnCtrl;     // botón entra
  late AnimationController _pulseCtrl;   // pulso botón
  late AnimationController _shimCtrl;    // shimmer botón
  late AnimationController _particleCtrl;// partículas

  // ── Animations ───────────────────────────────────────────────────────────
  late Animation<double> _bgFade;
  late Animation<double> _truckX, _truckFade, _truckBounce, _dustFade;
  late Animation<double> _logoScale, _logoFade, _logoY;
  late Animation<double> _glowOpacity;
  late Animation<double> _btnSlide, _btnFade;

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
        duration: const Duration(milliseconds: 800));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);

    // Orbes flotantes (loop continuo)
    _orb1Ctrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 6))..repeat(reverse: true);
    _orb2Ctrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 9))..repeat(reverse: true);

    // Línea de scan
    _scanCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400));

    // Camión
    _truckCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1600));
    _truckX = Tween<double>(begin: -0.25, end: 1.3).animate(
        CurvedAnimation(parent: _truckCtrl,
            curve: const Interval(0.0, 0.88, curve: Curves.easeInOut)));
    _truckFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 72),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_truckCtrl);
    _dustFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _truckCtrl,
            curve: const Interval(0.72, 0.95, curve: Curves.easeOut)));
    _bounceCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 280))..repeat();
    _truckBounce = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -5.0)
              .chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: -5.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
    ]).animate(_bounceCtrl);

    // Logo
    _logoCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.55, curve: Curves.easeIn)));
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.75, curve: Curves.elasticOut)));
    _logoY = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));

    // Brillo logo (glow pulsante)
    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.25, end: 0.60).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Botón
    _btnCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _btnCtrl,
            curve: const Interval(0.0, 0.7, curve: Curves.easeIn)));
    _btnSlide = Tween<double>(begin: 50, end: 0).animate(
        CurvedAnimation(parent: _btnCtrl,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut)));

    // Pulso botón
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat();

    // Shimmer botón
    _shimCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))..repeat();

    // Partículas
    _particleCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat();
  }

  Future<void> _run() async {
    setState(() {});
    await _bgCtrl.forward();
    _scanCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _showTruck = true);
    await _truckCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));

    setState(() { _showTruck = false; _showLogo = true; });
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _showBtn = true);
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _orb1Ctrl.dispose();
    _orb2Ctrl.dispose();
    _scanCtrl.dispose();
    _truckCtrl.dispose();
    _bounceCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _btnCtrl.dispose();
    _pulseCtrl.dispose();
    _shimCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() =>
      Navigator.pushReplacementNamed(context, AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [

            // ── Fondo degradado radial ────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.25),
                    radius: 1.15,
                    colors: [kAccent, kBlue, kBlueMid, kBlueDark],
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // ── Malla sutil ───────────────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(painter: _MeshPainter()),
            ),

            // ── Orbes animados ────────────────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_orb1Ctrl, _orb2Ctrl]),
              builder: (_, __) => Stack(
                children: [
                  Positioned(
                    top: -size.width * 0.15 + _orb1Ctrl.value * size.width * 0.06,
                    right: -size.width * 0.10,
                    child: _Orb(
                      radius: size.width * 0.52,
                      color: kGlow,
                      opacity: 0.13 + _orb1Ctrl.value * 0.06,
                    ),
                  ),
                  Positioned(
                    bottom: -size.width * 0.20 + _orb2Ctrl.value * size.width * 0.08,
                    left: -size.width * 0.15,
                    child: _Orb(
                      radius: size.width * 0.58,
                      color: kBlue,
                      opacity: 0.18 + _orb2Ctrl.value * 0.07,
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.10 + _orb1Ctrl.value * 12,
                    left: size.width * 0.60,
                    child: _Orb(
                      radius: size.width * 0.22,
                      color: kGlow,
                      opacity: 0.09 + _orb2Ctrl.value * 0.04,
                    ),
                  ),
                ],
              ),
            ),

            // ── Partículas flotantes ──────────────────────────────────────
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlePainter(progress: _particleCtrl.value),
                ),
              ),
            ),

            // ── Línea de scan ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (_, __) {
                if (_scanCtrl.value == 0) return const SizedBox.shrink();
                return Positioned(
                  top: _scanCtrl.value * size.height,
                  left: 0, right: 0,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.06),
                          Colors.white.withOpacity(0.20),
                          Colors.white.withOpacity(0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Camión animado ────────────────────────────────────────────
            if (_showTruck)
              AnimatedBuilder(
                animation: Listenable.merge([_truckCtrl, _bounceCtrl]),
                builder: (_, __) {
                  final xPos = _truckX.value * size.width;
                  return Positioned(
                    left: xPos - 75,
                    top: size.height * 0.44 + _truckBounce.value,
                    child: Opacity(
                      opacity: _truckFade.value.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 150, height: 75,
                        child: CustomPaint(
                          painter: _TruckPainter(progress: _truckCtrl.value),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // ── Polvo del camión ──────────────────────────────────────────
            if (_showTruck)
              AnimatedBuilder(
                animation: _dustFade,
                builder: (_, __) {
                  if (_dustFade.value < 0.01) return const SizedBox.shrink();
                  return Positioned(
                    right: 16,
                    top: size.height * 0.44 + 38,
                    child: Opacity(
                      opacity: (_dustFade.value * 0.55).clamp(0.0, 1.0),
                      child: CustomPaint(
                        size: const Size(90, 45),
                        painter: _DustPainter(),
                      ),
                    ),
                  );
                },
              ),

            // ── Logo — centrado ───────────────────────────────────────────
            if (_showLogo)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_logoFade, _logoScale, _logoY, _glowOpacity]),
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _logoY.value - size.height * 0.05),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Halo de luz
                              Container(
                                width: 300,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(75),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kGlow.withOpacity(_glowOpacity.value),
                                      blurRadius: 70,
                                      spreadRadius: 25,
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(
                                'assets/images/logo_trainyl.png',
                                width: 240,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Botón — centrado en X, pegado al fondo ────────────────────
            if (_showBtn)
              Align(
                alignment: const Alignment(0, 0.88),
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
}

// ═══════════════════════════════════════════════════════════════════════════
// Orbe de luz
// ═══════════════════════════════════════════════════════════════════════════

class _Orb extends StatelessWidget {
  final double radius;
  final Color color;
  final double opacity;
  const _Orb({required this.radius, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Malla de fondo sutil
// ═══════════════════════════════════════════════════════════════════════════

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Líneas diagonales más sutiles
    final diag = Paint()
      ..color = Colors.white.withOpacity(0.012)
      ..strokeWidth = 0.6;
    for (double d = -size.height; d < size.width + size.height; d += step * 2) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), diag);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter o) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Partículas flotantes
// ═══════════════════════════════════════════════════════════════════════════

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter({required this.progress});

  static final _rng = math.Random(42);
  static final _particles = List.generate(28, (i) => [
    _rng.nextDouble(), // x base
    _rng.nextDouble(), // y base
    _rng.nextDouble() * 2.5 + 1.0, // radio
    _rng.nextDouble(), // fase
    _rng.nextDouble() * 0.4 + 0.06, // opacidad max
    _rng.nextDouble() * 0.008 + 0.003, // velocidad
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = p[0] * size.width;
      final yBase = p[1] * size.height;
      final r = p[2];
      final phase = p[3];
      final opacity = p[4];
      final speed = p[5];

      final t = (progress + phase) % 1.0;
      final y = yBase - t * size.height * speed * 40;
      final yWrapped = ((y % size.height) + size.height) % size.height;

      // pulso de opacidad
      final pulse = (math.sin((progress + phase) * math.pi * 4) + 1) / 2;

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity * (0.5 + pulse * 0.5))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, yWrapped), r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter o) => o.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// Camión
// ═══════════════════════════════════════════════════════════════════════════

class _TruckPainter extends CustomPainter {
  final double progress;
  _TruckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wheelAngle = progress * math.pi * 10;

    final body = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dark = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    final accent = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    // Remolque
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.18, w * 0.58, h * 0.52),
        const Radius.circular(4),
      ),
      body,
    );
    // Líneas remolque
    for (int i = 1; i <= 3; i++) {
      final x = (w * 0.58 / 4) * i;
      canvas.drawRect(
        Rect.fromLTWH(x - 0.8, h * 0.18, 1.5, h * 0.52),
        dark,
      );
    }

    // Cabina
    final cabin = Path()
      ..moveTo(w * 0.60, h * 0.70)
      ..lineTo(w * 0.60, h * 0.30)
      ..quadraticBezierTo(w * 0.62, h * 0.18, w * 0.72, h * 0.18)
      ..lineTo(w * 0.84, h * 0.18)
      ..quadraticBezierTo(w * 0.96, h * 0.20, w * 1.00, h * 0.35)
      ..lineTo(w * 1.00, h * 0.70)
      ..close();
    canvas.drawPath(cabin, body);

    // Ventana
    final window = Path()
      ..moveTo(w * 0.63, h * 0.28)
      ..lineTo(w * 0.63, h * 0.22)
      ..quadraticBezierTo(w * 0.64, h * 0.18, w * 0.72, h * 0.18)
      ..lineTo(w * 0.82, h * 0.18)
      ..quadraticBezierTo(w * 0.91, h * 0.19, w * 0.95, h * 0.28)
      ..close();
    canvas.drawPath(window, accent);

    // Faro
    final headlight = Paint()..color = Colors.yellow.withOpacity(0.9);
    canvas.drawOval(Rect.fromLTWH(w * 0.976, h * 0.34, w * 0.024, h * 0.11),
        headlight);

    // Ruedas
    _wheel(canvas, Offset(w * 0.13, h * 0.73), h * 0.155, wheelAngle, body, dark, accent);
    _wheel(canvas, Offset(w * 0.42, h * 0.73), h * 0.155, wheelAngle, body, dark, accent);
    _wheel(canvas, Offset(w * 0.82, h * 0.73), h * 0.175, wheelAngle, body, dark, accent);
  }

  void _wheel(Canvas c, Offset center, double r, double angle,
      Paint body, Paint dark, Paint accent) {
    c.drawCircle(center, r,
        Paint()..color = body.color.withOpacity(0.88)..style = PaintingStyle.fill);
    c.drawCircle(center, r * 0.58,
        Paint()..color = body.color.withOpacity(0.38)..style = PaintingStyle.fill);
    final spoke = Paint()
      ..color = body.color.withOpacity(0.72)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final a = angle + (math.pi / 3) * i;
      c.drawLine(center,
          Offset(center.dx + math.cos(a) * r * 0.55,
              center.dy + math.sin(a) * r * 0.55),
          spoke);
    }
    c.drawCircle(center, r * 0.17, body);
  }

  @override
  bool shouldRepaint(_TruckPainter o) => o.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// Nube de polvo
// ═══════════════════════════════════════════════════════════════════════════

class _DustPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void circle(double x, double y, double r, double op) =>
        canvas.drawCircle(Offset(x * size.width, y * size.height), r,
            Paint()..color = Colors.white.withOpacity(op)..style = PaintingStyle.fill);
    circle(0.28, 0.50, 14, 0.28);
    circle(0.52, 0.40, 10, 0.20);
    circle(0.72, 0.60, 8,  0.14);
    circle(0.88, 0.45, 6,  0.10);
  }
  @override
  bool shouldRepaint(_DustPainter o) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Botón "Iniciar mi Jornada"
// ═══════════════════════════════════════════════════════════════════════════

class _JourneyButton extends StatefulWidget {
  final VoidCallback onTap;
  final AnimationController shimCtrl;
  final AnimationController pulseCtrl;
  const _JourneyButton({
    required this.onTap,
    required this.shimCtrl,
    required this.pulseCtrl,
  });
  @override
  State<_JourneyButton> createState() => _JourneyButtonState();
}

class _JourneyButtonState extends State<_JourneyButton> {
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
          final pulse = Tween<double>(begin: 1.0, end: 1.04)
              .chain(CurveTween(curve: Curves.easeInOut))
              .evaluate(widget.pulseCtrl);
          return Transform.scale(
            scale: _pressed ? 0.94 : pulse,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 272,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: _pressed
                ? const LinearGradient(
                    colors: [Color(0xFF0D2D61), Color(0xFF071428)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFF2A7AE4), // celeste brillante
                      Color(0xFF123C80), // azul marca
                      Color(0xFF091E42), // azul muy oscuro
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.50, 1.0],
                  ),
            border: Border.all(
              color: _pressed
                  ? Colors.white.withOpacity(0.20)
                  : Colors.white.withOpacity(0.45),
              width: 1.5,
            ),
            boxShadow: _pressed
                ? []
                : [
                    // Sombra principal azul profundo
                    BoxShadow(
                      color: const Color(0xFF071428).withOpacity(0.70),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    // Halo exterior luminoso celeste
                    BoxShadow(
                      color: const Color(0xFF2A7AE4).withOpacity(0.40),
                      blurRadius: 40,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                    // Brillo superior sutil (borde de luz)
                    BoxShadow(
                      color: Colors.white.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Brillo superior interno (highlight)
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Shimmer
                AnimatedBuilder(
                  animation: widget.shimCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ShimmerPainter(progress: widget.shimCtrl.value),
                    size: const Size(272, 62),
                  ),
                ),
                // Contenido
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícono con fondo circular sutil
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Iniciar mi Jornada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Color(0x55000000),
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
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
    final x = size.width * (progress * 1.7 - 0.35);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.18),
          Colors.transparent,
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(x - 60, 0, 120, size.height));
    canvas.drawPath(
      Path()
        ..moveTo(x - 50, 0)
        ..lineTo(x + 10, 0)
        ..lineTo(x - 10, size.height)
        ..lineTo(x - 70, size.height)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter o) => o.progress != progress;
}
