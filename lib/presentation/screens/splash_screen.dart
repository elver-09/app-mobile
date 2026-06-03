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
  static const Color kBlue      = Color(0xFF008DE1);
  static const Color kBlueDark  = Color(0xFF0070B8);
  static const Color kBlueDarker= Color(0xFF005A96);

  // ── Fase 1: punto azul → rellena pantalla ──
  late AnimationController _fillCtrl;
  late Animation<double>   _fillAnim;

  // ── Fase 2: punto blanco → rellena + logo aparece ──
  late AnimationController _whiteCtrl;
  late Animation<double>   _whiteAnim;
  late Animation<double>   _logoScaleAnim;
  late Animation<double>   _logoFadeAnim;
  late Animation<double>   _subtitleFadeAnim;

  // ── Fase 3: contracción lateral ──
  late AnimationController _contractCtrl;
  late Animation<double>   _contractAnim;
  late Animation<double>   _btnFadeAnim;
  late Animation<double>   _btnSlideAnim;
  late Animation<double>   _logoFinalFadeAnim;

  // ── Pulso decorativo sobre el logo (fase 2) ──
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  bool _showFill      = false;
  bool _showWhite     = false;
  bool _showLogoBlue  = false;
  bool _showContract  = false;
  bool _showFinal     = false;

  @override
  void initState() {
    super.initState();
    _setup();
    _run();
  }

  void _setup() {
    // Fase 1 – 1.1s
    _fillCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100));
    _fillAnim = CurvedAnimation(parent: _fillCtrl, curve: Curves.easeInOut);

    // Fase 2 – 1.0s
    _whiteCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1050));
    _whiteAnim = CurvedAnimation(parent: _whiteCtrl, curve: Curves.easeOut);
    _logoScaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _whiteCtrl,
          curve: const Interval(0.35, 1.0, curve: Curves.elasticOut)));
    _logoFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _whiteCtrl,
          curve: const Interval(0.3, 0.75, curve: Curves.easeIn)));
    _subtitleFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _whiteCtrl,
          curve: const Interval(0.6, 1.0, curve: Curves.easeIn)));

    // Pulso – loop
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Fase 3 – 1.3s
    _contractCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1300));
    _contractAnim = CurvedAnimation(parent: _contractCtrl,
        curve: Curves.easeInOut);
    _btnFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contractCtrl,
          curve: const Interval(0.60, 1.0, curve: Curves.easeOut)));
    _btnSlideAnim = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(parent: _contractCtrl,
          curve: const Interval(0.60, 1.0, curve: Curves.easeOut)));
    _logoFinalFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contractCtrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 450));

    // Fase 1
    setState(() => _showFill = true);
    await _fillCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 120));

    // Fase 2
    setState(() { _showWhite = true; _showLogoBlue = true; });
    await _whiteCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));

    // Fase 3
    _pulseCtrl.stop();
    setState(() { _showContract = true; _showFinal = true; });
    _contractCtrl.forward();
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _whiteCtrl.dispose();
    _pulseCtrl.dispose();
    _contractCtrl.dispose();
    super.dispose();
  }

  void _goToLogin() =>
      Navigator.pushReplacementNamed(context, AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxR = math.sqrt(size.width * size.width + size.height * size.height) / 2 + 20;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [

          // ── Fase 1: círculo azul desde punto hasta cubrir ──
          if (_showFill)
            AnimatedBuilder(
              animation: _fillAnim,
              builder: (_, __) {
                if (_showContract) return const SizedBox.shrink();
                final r = 6 + (maxR - 6) * _fillAnim.value;
                return _Circle(color: kBlue, radius: r);
              },
            ),

          // ── Fase 3: contracción lateral ──
          if (_showContract)
            AnimatedBuilder(
              animation: _contractAnim,
              builder: (_, __) {
                final rem  = 1.0 - _contractAnim.value;
                final half = (size.width / 2) * rem;
                if (half <= 0) return const SizedBox.shrink();
                return Row(children: [
                  Container(width: half, height: size.height, color: kBlue),
                  Expanded(child: Container(color: Colors.white)),
                  Container(width: half, height: size.height, color: kBlue),
                ]);
              },
            ),

          // ── Fase 2: círculo blanco ──
          if (_showWhite)
            AnimatedBuilder(
              animation: _whiteAnim,
              builder: (_, __) {
                if (_showContract) return const SizedBox.shrink();
                final r = 6 + (maxR - 6) * _whiteAnim.value;
                return _Circle(color: Colors.white, radius: r);
              },
            ),

          // ── Logo sobre fondo azul (fase 2) ──
          if (_showLogoBlue && !_showContract)
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_logoFadeAnim, _logoScaleAnim, _pulseAnim]),
                builder: (_, child) => Opacity(
                  opacity: _logoFadeAnim.value,
                  child: Transform.scale(
                    scale: _logoScaleAnim.value,
                    child: child,
                  ),
                ),
                child: _SplashLogoBlock(
                  iconColor: Colors.white,
                  nameColor: Colors.white,
                  subtitleOpacity: _subtitleFadeAnim,
                  showGlow: true,
                  glowColor: Colors.white,
                ),
              ),
            ),

          // ── Contenido final (fondo blanco) ──
          if (_showFinal)
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_contractAnim, _btnFadeAnim, _btnSlideAnim, _logoFinalFadeAnim]),
                builder: (_, child) => child!,
                child: _FinalContent(
                  logoFade: _logoFinalFadeAnim,
                  btnFade: _btnFadeAnim,
                  btnSlide: _btnSlideAnim,
                  onTap: _goToLogin,
                ),
              ),
            ),

          // ── Estado 0: punto azul tiny ──
          if (!_showFill)
            Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(
                color: kBlue, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bloque de logo (pantalla azul)
// ═══════════════════════════════════════════════════════════════════════════

class _SplashLogoBlock extends StatelessWidget {
  final Color iconColor;
  final Color nameColor;
  final Animation<double> subtitleOpacity;
  final bool showGlow;
  final Color glowColor;

  const _SplashLogoBlock({
    required this.iconColor,
    required this.nameColor,
    required this.subtitleOpacity,
    required this.showGlow,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Halo de brillo detrás del logo
        Stack(
          alignment: Alignment.center,
          children: [
            if (showGlow)
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.20),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: 100, height: 100,
              child: CustomPaint(
                painter: _TrainylLogoPainter(color: iconColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'TRAINYL',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: nameColor,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: 6),
        FadeTransition(
          opacity: subtitleOpacity,
          child: Text(
            'logística de confianza',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: nameColor.withOpacity(0.80),
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Contenido final (logo azul + botón)
// ═══════════════════════════════════════════════════════════════════════════

class _FinalContent extends StatelessWidget {
  final Animation<double> logoFade;
  final Animation<double> btnFade;
  final Animation<double> btnSlide;
  final VoidCallback onTap;

  static const Color kBlue     = Color(0xFF008DE1);
  static const Color kBlueDark = Color(0xFF0070B8);

  const _FinalContent({
    required this.logoFade,
    required this.btnFade,
    required this.btnSlide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([logoFade, btnFade, btnSlide]),
      builder: (_, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Opacity(
              opacity: logoFade.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 96, height: 96,
                    child: CustomPaint(
                      painter: _TrainylLogoPainter(color: kBlue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TRAINYL',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kBlue,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'logística de confianza',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: kBlue.withOpacity(0.60),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 52),

            // Botón
            Opacity(
              opacity: btnFade.value,
              child: Transform.translate(
                offset: Offset(0, btnSlide.value),
                child: _JourneyButton(onTap: onTap),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Botón "Iniciar mi Jornada"
// ═══════════════════════════════════════════════════════════════════════════

class _JourneyButton extends StatefulWidget {
  final VoidCallback onTap;
  const _JourneyButton({required this.onTap});

  @override
  State<_JourneyButton> createState() => _JourneyButtonState();
}

class _JourneyButtonState extends State<_JourneyButton>
    with SingleTickerProviderStateMixin {
  static const Color kBlue     = Color(0xFF008DE1);
  static const Color kBlueDark = Color(0xFF0070B8);

  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() { _shimCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 240,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [kBlue, kBlueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kBlue.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer
              AnimatedBuilder(
                animation: _shimCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ShimmerPainter(progress: _shimCtrl.value),
                  size: const Size(240, 52),
                ),
              ),
              const Text(
                'Iniciar mi Jornada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════

class _Circle extends StatelessWidget {
  final Color color;
  final double radius;
  const _Circle({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: radius * 2, height: radius * 2,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * (progress * 1.6 - 0.3);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, Colors.white.withOpacity(0.18), Colors.transparent],
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

// ─── Painter: logo real Trainyl (hexágono redondeado + pin con círculo y +) ──

// ─── Painter: logo real Trainyl (hexágono redondeado + pin con círculo y +) ──

class _TrainylLogoPainter extends CustomPainter {
  final Color color;
  _TrainylLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;
    final cx = w / 2;
    final sw = w * 0.058;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Hexágono exterior con esquinas redondeadas ──────────────────────
    final hexR   = w * 0.44;
    final hexCY  = h * 0.44;
    final corner = w * 0.09;   // radio de esquina
    final hexPath = _roundedHexPath(cx, hexCY, hexR, corner);
    canvas.drawPath(hexPath, stroke);

    // ── Pin de ubicación: cuerpo circular + punta ────────────────────────
    final pinCY   = hexCY - h * 0.04;
    final pinR    = w * 0.185;
    final pinTipY = pinCY + pinR + w * 0.16;

    // Círculo del pin
    canvas.drawCircle(Offset(cx, pinCY), pinR, stroke);

    // Punta del pin (triángulo hacia abajo) — dos líneas desde el borde inferior del círculo
    final leftX  = cx - pinR * 0.55;
    final rightX = cx + pinR * 0.55;
    final baseY  = pinCY + pinR * 0.82;

    canvas.drawLine(Offset(leftX, baseY),  Offset(cx, pinTipY), stroke);
    canvas.drawLine(Offset(rightX, baseY), Offset(cx, pinTipY), stroke);

    // ── Símbolo "+" (cross/más) dentro del círculo ───────────────────────
    final crossLen = pinR * 0.50;
    final crossSW  = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.82
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, pinCY - crossLen),
      Offset(cx, pinCY + crossLen * 0.4),  // un poco más corto abajo (lo tapa la punta)
      crossSW,
    );
    canvas.drawLine(
      Offset(cx - crossLen, pinCY),
      Offset(cx + crossLen, pinCY),
      crossSW,
    );
  }

  // Hexágono con esquinas redondeadas
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
