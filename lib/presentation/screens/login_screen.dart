import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/controllers/auth_controller.dart';
import 'package:trainyl_2_0/presentation/screens/choose_sede.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Paleta de marca ──────────────────────────────────────────────────────
  static const Color kBlue     = Color(0xFF123C80);
  static const Color kBlueMid  = Color(0xFF0D2D61);
  static const Color kBlueDark = Color(0xFF091E42);
  static const Color kBlueSoft = Color(0xFFEAF0FB);

  late final AuthController _auth;
  bool _loading = false;
  bool _showPassword = false;

  // Animación de entrada general
  late AnimationController _entranceCtrl;
  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<double> _formSlide;
  late Animation<double> _formFade;
  late Animation<double> _btnScale;

  // Shimmer continuo en el botón
  late AnimationController _shimmerCtrl;

  // Focus nodes
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _auth = AuthController(
      client: OdooClient(
        baseUrl: 'https://trainyl.digilab.pe',
        db: 'trainyl-prd',
      ),
    );

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerSlide = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOut)),
    );
    _formSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _entranceCtrl,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl,
          curve: const Interval(0.3, 0.85, curve: Curves.easeOut)),
    );
    _btnScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl,
          curve: const Interval(0.65, 1.0, curve: Curves.elasticOut)),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _userFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shimmerCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _auth.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final result = await _auth.login();
      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Credenciales inválidas o usuario no es conductor'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        _buildPageRoute(
          ChooseSede(
            token: result.token,
            odooClient: _auth.client,
            driver: {
              'name': result.driver.name,
              'work_email': result.driver.workEmail,
              'work_phone': result.driver.workPhone,
              'job': result.driver.job,
              'license_number': result.driver.licenseNumber,
              'image_1920': result.driver.imageBase64,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  PageRoute _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionsBuilder: (_, anim, __, child) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Ola decorativa con degradado de marca ─────────────────────
          AnimatedBuilder(
            animation: _headerFade,
            builder: (_, __) => Opacity(
              opacity: _headerFade.value,
              child: Transform.translate(
                offset: Offset(0, _headerSlide.value),
                child: SizedBox(
                  height: size.height * 0.50,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _GradientWavePainter(
                      colorTop: kBlue,
                      colorMid: kBlueMid,
                      colorBottom: kBlueDark,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Partículas decorativas flotantes ──────────────────────────
          ..._buildParticles(size),

          // ── Contenido scrollable ──────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header con logo
                  AnimatedBuilder(
                    animation: _headerFade,
                    builder: (_, child) => Opacity(
                      opacity: _headerFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _headerSlide.value),
                        child: child,
                      ),
                    ),
                    child: SizedBox(
                      height: size.height * 0.38,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo completo en blanco
                          Image.asset(
                            'assets/images/logo_trainyl.png',
                            width: 230,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tu jornada comienza aquí',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.75),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Tarjeta del formulario ────────────────────────────
                  AnimatedBuilder(
                    animation: _formFade,
                    builder: (_, child) => Opacity(
                      opacity: _formFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _formSlide.value),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.getResponsiveSize(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: kBlue.withOpacity(0.14),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(responsive.getResponsiveSize(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: responsive.headingMediumFontSize,
                                fontWeight: FontWeight.w700,
                                color: kBlueDark,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: responsive.getResponsiveSize(22)),

                            // Campo usuario
                            _AnimatedInputField(
                              controller: _auth.userCtrl,
                              focusNode: _userFocus,
                              hint: 'Correo electrónico',
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              activeColor: kBlue,
                              fontSize: responsive.bodySmallFontSize + 1,
                            ),
                            SizedBox(height: responsive.getResponsiveSize(14)),

                            // Campo contraseña
                            _AnimatedInputField(
                              controller: _auth.passCtrl,
                              focusNode: _passFocus,
                              hint: 'Contraseña',
                              icon: Icons.lock_outline_rounded,
                              obscureText: !_showPassword,
                              activeColor: kBlue,
                              fontSize: responsive.bodySmallFontSize + 1,
                              suffix: IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    _showPassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    key: ValueKey(_showPassword),
                                    color: _showPassword
                                        ? kBlue
                                        : const Color(0xFFAAAAAA),
                                    size: 20,
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                            SizedBox(height: responsive.getResponsiveSize(26)),

                            // Botón Ingresar
                            AnimatedBuilder(
                              animation: _btnScale,
                              builder: (_, child) => Transform.scale(
                                scale: _btnScale.value,
                                child: child,
                              ),
                              child: _ShimmerButton(
                                label: 'Ingresar',
                                onTap: _loading ? null : _handleLogin,
                                loading: _loading,
                                colorTop: kBlue,
                                colorBottom: kBlueDark,
                                shimmerCtrl: _shimmerCtrl,
                                height: responsive.buttonHeight,
                                fontSize: responsive.bodyMediumFontSize,
                              ),
                            ),
                            SizedBox(height: responsive.getResponsiveSize(18)),

                            Text(
                              'Al ingresar, aceptas nuestros Términos y Política de Privacidad',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: responsive.bodySmallFontSize - 1,
                                color: const Color(0xFFBBBBBB),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.getResponsiveSize(32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticles(Size size) {
    final positions = [
      const Offset(0.08, 0.04),
      const Offset(0.92, 0.06),
      const Offset(0.15, 0.28),
      const Offset(0.85, 0.22),
      const Offset(0.5, 0.03),
    ];
    final radii = [14.0, 10.0, 7.0, 12.0, 8.0];

    return List.generate(positions.length, (i) {
      return Positioned(
        left: positions[i].dx * size.width - radii[i],
        top: positions[i].dy * size.height - radii[i],
        child: AnimatedBuilder(
          animation: _headerFade,
          builder: (_, __) => Opacity(
            opacity: _headerFade.value * 0.18,
            child: Container(
              width: radii[i] * 2,
              height: radii[i] * 2,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Campo de texto animado ──────────────────────────────────────────────────

class _AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final Color activeColor;
  final double fontSize;
  final Widget? suffix;

  const _AnimatedInputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.activeColor,
    required this.fontSize,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? activeColor : Colors.transparent,
          width: 1.8,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFF1A1A2E),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFFBBBBBB),
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              icon,
              color: isFocused ? activeColor : const Color(0xFFCCCCCC),
              size: 20,
            ),
          ),
          suffixIcon: suffix,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ─── Botón con shimmer y degradado de marca ───────────────────────────────────

class _ShimmerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Color colorTop;
  final Color colorBottom;
  final AnimationController shimmerCtrl;
  final double height;
  final double fontSize;

  const _ShimmerButton({
    required this.label,
    required this.onTap,
    required this.loading,
    required this.colorTop,
    required this.colorBottom,
    required this.shimmerCtrl,
    required this.height,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: loading
                ? [Colors.grey.shade400, Colors.grey.shade300]
                : [colorTop, colorBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: colorTop.withOpacity(0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!loading)
                AnimatedBuilder(
                  animation: shimmerCtrl,
                  builder: (_, __) {
                    return Positioned.fill(
                      child: CustomPaint(
                        painter: _ShimmerPainter(progress: shimmerCtrl.value),
                      ),
                    );
                  },
                ),
              loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * (progress * 1.6 - 0.3);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(x - 60, 0, 120, size.height))
      ..blendMode = BlendMode.srcOver;

    final path = Path()
      ..moveTo(x - 50, 0)
      ..lineTo(x + 10, 0)
      ..lineTo(x - 10, size.height)
      ..lineTo(x - 70, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ─── Ola con degradado de marca ─────────────────────────────────────────────

class _GradientWavePainter extends CustomPainter {
  final Color colorTop;
  final Color colorMid;
  final Color colorBottom;

  _GradientWavePainter({
    required this.colorTop,
    required this.colorMid,
    required this.colorBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Forma de ola
    final wavePath = Path()
      ..lineTo(0, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.97,
        size.width * 0.5, size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.78,
        size.width, size.height * 0.90,
      )
      ..lineTo(size.width, 0)
      ..close();

    // Gradiente diagonal sobre la ola principal
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colorTop, colorMid, colorBottom],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(wavePath, gradPaint);

    // Segunda ola más suave
    final wave2Path = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.3, size.height * 1.02,
        size.width * 0.6, size.height * 0.92,
      )
      ..quadraticBezierTo(
        size.width * 0.82, size.height * 0.85,
        size.width, size.height * 0.96,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final grad2Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorMid.withOpacity(0.40),
          colorBottom.withOpacity(0.30),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(wave2Path, grad2Paint);

    // Círculo decorativo sutil en la esquina superior derecha
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15),
        size.width * 0.28, circlePaint);

    // Círculo pequeño en la esquina izquierda
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.25),
        size.width * 0.12, circlePaint);
  }

  @override
  bool shouldRepaint(_GradientWavePainter old) =>
      old.colorTop != colorTop ||
      old.colorMid != colorMid ||
      old.colorBottom != colorBottom;
}

// ─── Painter: logo Trainyl — hexágono con cubo isométrico ───────────────────

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

    // ── Hexágono exterior redondeado ────────────────────────────────────
    final hexR   = w * 0.46;
    final corner = w * 0.08;
    canvas.drawPath(_roundedHexPath(cx, cy, hexR, corner), stroke);

    // ── Cubo isométrico interior ────────────────────────────────────────
    final cr = w * 0.22;
    const double iso = 0.58;

    final top    = Offset(cx,      cy - cr * iso);
    final left   = Offset(cx - cr, cy);
    final right  = Offset(cx + cr, cy);
    final bottom = Offset(cx,      cy + cr * iso);
    final tl     = Offset(cx - cr, cy - cr * iso);
    final tr     = Offset(cx + cr, cy - cr * iso);
    final bl     = Offset(cx - cr, cy + cr * iso);
    final br     = Offset(cx + cr, cy + cr * iso);

    // cara superior
    canvas.drawPath(
      Path()
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(top.dx, top.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(cx, cy)
        ..close(),
      stroke,
    );
    // cara izquierda
    canvas.drawPath(
      Path()
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(bl.dx, bl.dy)
        ..lineTo(cx, cy)
        ..close(),
      stroke,
    );
    // cara derecha
    canvas.drawPath(
      Path()
        ..moveTo(tr.dx, tr.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(cx, cy)
        ..close(),
      stroke,
    );
    // arista inferior central
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
      final toPrev = prev - curr;
      final toNext = next - curr;
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
