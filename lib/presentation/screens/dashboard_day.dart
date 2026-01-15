import 'package:flutter/material.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/statistics_section.dart';
import '../widgets/dashboard/delivery_progress_section.dart';
import '../widgets/dashboard/next_action_section.dart';
import '../widgets/dashboard/order_control_section.dart';
import '../widgets/dashboard/rescan_orders_button.dart';

class DashboardDay extends StatelessWidget {
  const DashboardDay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardHeader(
        userName: 'Carlos',
        currentDate: 'Hoy · Lun 12 Feb 2025',
        headquartersName: 'Centro',
        headquartersZone: 'Norte',
        onProfileTap: () {},
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics
                StatisticsSection(
                  assigned: 24,
                  scanned: 24,
                  delivered: 0,
                  pending: 24,
                ),
                // Delivery progress
                DeliveryProgressSection(
                  progress: 0.0,
                  deliveryPercentage: 0,
                ),
                // Next action
                NextActionSection(
                  routeName: 'Iniciar Ruta 1 · Centro',
                  orderCount: 12,
                  distanceKm: 34,
                  etaFirstDelivery: '08:40',
                  onStartRoute: () {},
                ),
                const SizedBox(height: 24),
                // Order control
                const OrderControlSection(),
                const SizedBox(height: 32),
                // Start route button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Empezar Ruta 1',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Rescan button
                RescanOrdersButton(
                  onPressed: () {},
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey.shade600,
        onTap: (index) {},
      ),
    );
  }
}