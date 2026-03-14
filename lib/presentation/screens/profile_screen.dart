import 'package:flutter/material.dart';
import 'package:trainyl_2_0/presentation/screens/login_screen.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverProfileScreen extends StatelessWidget {
  final Map<String, dynamic> driver;
  const DriverProfileScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final String name = driver['name'] ?? '';
    final String workEmail = driver['work_email'] ?? '';
    final String workPhone = driver['work_phone'] ?? '';
    final String job = driver['job'] ?? '';
    final String? imageBase64 = driver['image_1920'] ?? driver['imageBase64'];
    final String licenseNumber = driver['license_number'] ?? '';

    ImageProvider? profileImage;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        profileImage = MemoryImage(
          Uri.parse('data:image/png;base64,$imageBase64').data!.contentAsBytes(),
        );
      } catch (_) {
        profileImage = null;
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perfil del chofer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDBEAFE), Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFF2563EB), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFDBEAFE),
                        backgroundImage: profileImage,
                        child: profileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Color(0xFF1D4ED8),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (licenseNumber.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.credit_card, size: 16, color: Color(0xFF2563EB)),
                                SizedBox(width: 6),
                                Text(
                                  'Licencia: $licenseNumber',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos del chofer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileRowPro(
                      icon: Icons.person,
                      label: 'Nombre',
                      value: name,
                    ),
                    const SizedBox(height: 14),
                    _ProfileRowPro(
                      icon: Icons.mail_outline,
                      label: 'Correo',
                      value: workEmail,
                      isCopyable: true,
                      isEmail: true,
                    ),
                    const SizedBox(height: 14),
                    _ProfileRowPro(
                      icon: Icons.phone,
                      label: 'Teléfono',
                      value: workPhone,
                      isCopyable: true,
                    ),
                    const SizedBox(height: 14),
                    _ProfileRowPro(
                      icon: Icons.badge_outlined,
                      label: 'Cargo',
                      value: job,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}


class _ProfileRowPro extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isCopyable;
  final bool isEmail;

  const _ProfileRowPro({
    required this.icon,
    required this.label,
    required this.value,
    this.isCopyable = false,
    this.isEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF60A5FA)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    if (isCopyable)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: value));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$label copiado')),
                            );
                          },
                          child: Icon(Icons.copy, size: 16, color: theme.primaryColor.withOpacity(0.7)),
                        ),
                      ),
                    if (isEmail)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: GestureDetector(
                          onTap: () async {
                            final uri = Uri(scheme: 'mailto', path: value);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Icon(Icons.open_in_new, size: 16, color: theme.primaryColor.withOpacity(0.7)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
