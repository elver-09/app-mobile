import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/controllers/auth_controller.dart';
import 'package:trainyl_2_0/presentation/screens/choose_sede.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _auth;
  bool _loading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _auth = AuthController(
      client: OdooClient(
        baseUrl: 'https://trainyl.digilab.pe',
        db: 'trainyl-prd',
      ),
    );
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final result = await _auth.login();
      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales inválidas o usuario no es conductor')),
        );
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChooseSede(
            token: result.token,
            odooClient: _auth.client,
            driverName: result.driver.name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.getResponsiveSize(20),
                vertical: responsive.getResponsiveSize(48),
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                padding: EdgeInsets.all(responsive.getResponsiveSize(20)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(responsive.borderRadius + 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Container(
                        height: responsive.getResponsiveSize(64),
                        width: responsive.getResponsiveSize(64),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 4, 91, 241),
                          borderRadius: BorderRadius.circular(responsive.borderRadius + 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 4, 91, 241).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: responsive.headingLargeFontSize,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(16)),
                    Text(
                      'Inicia Tu Jornada',
                      style: TextStyle(
                        fontSize: responsive.headingMediumFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(8)),
                    Align(
                      alignment: Alignment.center,
                        child: Text(
                        'Ingrese para iniciar rutas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: responsive.headingSmallFontSize,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(24)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Usuario',
                        style: TextStyle(
                          fontSize: responsive.bodySmallFontSize,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(10)),
                    TextField(
                      controller: _auth.userCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: responsive.getResponsiveSize(14),
                          vertical: responsive.getResponsiveSize(14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(responsive.borderRadius),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(responsive.borderRadius),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(responsive.borderRadius),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(20)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PIN / Contraseña',
                        style: TextStyle(
                          fontSize: responsive.bodySmallFontSize,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(10)),
                    TextField(
                      controller: _auth.passCtrl,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: '••••••',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: responsive.getResponsiveSize(14),
                          vertical: responsive.getResponsiveSize(14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(responsive.borderRadius),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(responsive.borderRadius),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(responsive.borderRadius),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(30)),
                    SizedBox(
                      width: double.infinity,
                      height: responsive.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 4, 91, 241),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(responsive.borderRadius),
                          ),
                        ),
                        child: _loading
                            ? SizedBox(
                                width: responsive.getResponsiveSize(20),
                                height: responsive.getResponsiveSize(20),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Ingresar',
                                style: TextStyle(
                                  fontSize: responsive.bodyMediumFontSize,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}