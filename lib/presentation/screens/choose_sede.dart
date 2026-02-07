import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/constants/route_status.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/route_model.dart';
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
    final meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    final dia = dias[now.weekday % 7];
    final mes = meses[now.month - 1];

    return 'Hoy · $dia ${now.day} $mes';
  }

  // Obtiene las órdenes para todas las rutas y las agrega a cada ruta
  Future<List<RouteItem>> _getRoutesWithOrders(
      List<RouteItem> routes) async {
    final routesWithOrders = <RouteItem>[];

    for (var route in routes) {
      try {
        final orderResponse = await widget.odooClient.fetchRouteOrders(
          token: widget.token,
          routeId: route.id,
        );

        final routeWithOrders = RouteItem(
          id: route.id,
          name: route.name,
          zone: route.zone,
          fleet: route.fleet,
          rutaDate: route.rutaDate,
          ordersQty: route.ordersQty,
          planned: route.planned,
          confirmed: route.confirmed,
          delivered: route.delivered,
          confirmedPercent: route.confirmedPercent,
          orders: orderResponse.orders,
        );
        routesWithOrders.add(routeWithOrders);
      } catch (e) {
        print('Error obteniendo órdenes de ruta ${route.id}: $e');
        routesWithOrders.add(route);
      }
    }

    return routesWithOrders;
  }
  Map<String, int> _getRouteStatistics(List<RouteItem> routes) {
    int pendiente = 0;
    int terminado = 0;

    for (var route in routes) {
      switch (route.status) {
        case RouteStatus.completed:
          terminado++;
          break;
        case RouteStatus.pending:
          pendiente++;
          break;
      }
    }

    return {
      'pendiente': pendiente,
      'terminado': terminado,
    };
  }

  // Calcula estadísticas de órdenes dinámicamente basadas en las rutas
  Future<Map<String, int>> _getOrderStatistics(List<RouteItem> routes) async {
    int pendiente = 0;
    int en_curso = 0;
    int entregado = 0;
    int rechazado = 0;

    for (var route in routes) {
      try {
        final orders = await widget.odooClient.fetchRouteOrders(
          token: widget.token,
          routeId: route.id,
        );

        for (var order in orders.orders) {
          switch (order.planningStatus) {
            case 'pending':
              pendiente++;
              break;
            case 'start_of_route':
              en_curso++;
              break;
            case 'delivered':
              entregado++;
              break;
            case 'cancelled':
              rechazado++;
              break;
            default:
              pendiente++;
          }
        }
      } catch (e) {
        print('Error obteniendo órdenes de ruta ${route.id}: $e');
      }
    }

    return {
      'pendiente': pendiente,
      'en_curso': en_curso,
      'entregado': entregado,
      'rechazado': rechazado,
    };
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
                ),
                const SizedBox(height: 5),
                // Charts section
                FutureBuilder<List<RouteItem>>(
                  future: _routesFuture.then(_getRoutesWithOrders),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final routes = snapshot.data ?? [];
                    final routeStats = _getRouteStatistics(routes);

                    return Container(
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
                                ChartData(
                                  'Pendiente',
                                  routeStats['pendiente'] ?? 0,
                                  Colors.grey,
                                ),
                                ChartData(
                                  'Terminado',
                                  routeStats['terminado'] ?? 0,
                                  Colors.green,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FutureBuilder<Map<String, int>>(
                              future: _getOrderStatistics(routes),
                              builder: (context, orderSnapshot) {
                                if (orderSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                }

                                final orderStats = orderSnapshot.data ?? {};

                                return PieChartWidget(
                                  title: 'Estados de órdenes',
                                  data: [
                                    ChartData(
                                      'Pendiente',
                                      orderStats['pendiente'] ?? 0,
                                      Colors.grey,
                                    ),
                                    ChartData(
                                      'En curso',
                                      orderStats['en_curso'] ?? 0,
                                      Colors.blue,
                                    ),
                                    ChartData(
                                      'Entregado',
                                      orderStats['entregado'] ?? 0,
                                      Colors.green,
                                    ),
                                    ChartData(
                                      'Rechazado',
                                      orderStats['rechazado'] ?? 0,
                                      Colors.red,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                  future: _routesFuture.then(_getRoutesWithOrders),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
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
                                stops: route.ordersQty,
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
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Rutas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}