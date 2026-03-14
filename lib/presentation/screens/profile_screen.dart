import 'package:flutter/material.dart';
import 'package:trainyl_2_0/presentation/screens/login_screen.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perfil del chofer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Juan Pérez Gómez',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Chofer de reparto',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Foto de perfil (demo)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildSection(
                title: 'Datos del chofer',
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileRow(
                      icon: Icons.person,
                      label: 'Nombre',
                      value: 'Juan',
                    ),
                    SizedBox(height: 9),
                    _ProfileRow(
                      icon: Icons.badge_outlined,
                      label: 'Apellidos',
                      value: 'Pérez Gómez',
                    ),
                    SizedBox(height: 9),
                    _ProfileRow(
                      icon: Icons.alternate_email,
                      label: 'Usuario',
                      value: 'jperez',
                    ),
                    SizedBox(height: 9),
                    _ProfileRow(
                      icon: Icons.mail_outline,
                      label: 'Correo',
                      value: 'jperez@empresa.com',
                    ),
                    SizedBox(height: 9),
                    _ProfileRow(
                      icon: Icons.phone,
                      label: 'Teléfono',
                      value: '+51 999 888 777',
                    ),
                    SizedBox(height: 9),
                    _ProfileRow(
                      icon: Icons.business_outlined,
                      label: 'Sede',
                      value: 'Lima Norte',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildSection(
                title: 'Datos del vehículo',
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileRow(
                      icon: Icons.local_shipping,
                      label: 'Vehículo',
                      value: 'Camión Isuzu NQR',
                    ),
                    SizedBox(height: 9),
                    _ProfileRow(
                      icon: Icons.badge,
                      label: 'Placa',
                      value: 'ABC-123',
                    ),
                    SizedBox(height: 9),
                    _ProfileRow(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Unidad',
                      value: 'UN-07',
                    ),
                    SizedBox(height: 9),
                    _ProfileRow(
                      icon: Icons.verified_outlined,
                      label: 'Licencia',
                      value: 'A-2B',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
