import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/route_model.dart';
import 'package:trainyl_2_0/presentation/screens/scan_assigned_orders.dart';
import 'package:trainyl_2_0/presentation/screens/route_orders_screen.dart';
import '../widgets/choose_sede/sede_header.dart';
import '../widgets/choose_sede/pie_chart_widget.dart';
import '../widgets/choose_sede/route_card.dart';

class ChooseSede extends StatefulWidget {
  final String token;
  final OdooClient odooClient;
  final String driverName;

  const ChooseSede({
    super.key,
    required this.token,
    required this.odooClient,
    required this.driverName,
  });

  @override
  State<ChooseSede> createState() => _ChooseSedeState();
}

class _ChooseSedeState extends State<ChooseSede> {
  int _selectedIndex = 1; // Rutas tab selected
  late Future<List<RouteItem>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = widget.odooClient.fetchTodayRoutes(widget.token);
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final dia = dias[now.weekday % 7];
    final mes = meses[now.month - 1];
    
    return 'Hoy · $dia ${now.day} $mes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SedeHeader(
                  formattedDate: _getFormattedDate(),
                  headquartersName: 'Centro\nNorte',
                ),
                const SizedBox(height: 24),
                // Charts section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChartWidget(
                          title: 'Estados de rutas',
                          data: [
                            ChartData('Pendiente', 1, Colors.grey),
                            ChartData('En\nprogreso', 2, Colors.blue),
                            ChartData('Terminado', 0, Colors.green),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PieChartWidget(
                          title: 'Estados de órdenes',
                          data: [
                            ChartData('Pendiente', 16, Colors.grey),
                            ChartData('Entregado', 8, Colors.green),
                            ChartData('Rechazado', 0, Colors.red),
                            ChartData('Sin\nescanear', 0, Colors.lightBlue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Routes section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rutas de hoy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.filter_list, size: 18, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Ordenadas por inicio',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Route cards - Loaded from Odoo
                FutureBuilder<List<RouteItem>>(
                  future: _routesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    final routes = snapshot.data ?? [];
                    if (routes.isEmpty) {
                      return const Center(
                        child: Text('No hay rutas asignadas para hoy'),
                      );
                    }
                    return Column(
                      children: [
                        ...routes.asMap().entries.map((entry) {
                          final route = entry.value;
                          final statusColor = Color(route.getStatusColor());
                          return Column(
                            children: [
                              RouteCard(
                                routeId: route.id,
                                routeName: route.name,
                                title: '${route.name} · ${route.zone}',
                                status: route.statusDisplay,
                                stops: route.confirmed,
                                orders: route.ordersQty,
                                progressText: route.progressText,
                                progress: route.progressValue,
                                statusColor: statusColor,
                                inProgress: route.inProgress,
                                onTapDetail: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RouteOrdersScreen(
                                        routeId: route.id,
                                        routeName: route.name,
                                        token: widget.token,
                                        odooClient: widget.odooClient,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (entry.key < routes.length - 1)
                                const SizedBox(height: 12),
                            ],
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanAssignedOrders(
                            nombreSede: 'Centro Norte',
                            ordenesAsignadas: 24,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.navigation, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Continuar última ruta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}