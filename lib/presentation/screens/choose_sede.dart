import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/constants/route_status.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/route_model.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
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
          stateRoute: route.stateRoute,
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
    int porValidar = 0;
    int enRuta = 0;
    int terminado = 0;

    for (var route in routes) {
      if (route.status == RouteStatus.finished) {
        terminado++;
      } else if (route.status == RouteStatus.inRoute) {
        enRuta++;
      } else {
        porValidar++;
      }
    }

    return {
      'por_validar': porValidar,
      'en_ruta': enRuta,
      'terminado': terminado,
    };
  }

  // Calcula estadísticas de órdenes dinámicamente basadas en las rutas
  Future<Map<String, int>> _getOrderStatistics(List<RouteItem> routes) async {
    int pendiente = 0;
    int enTransporte = 0;
    int enCurso = 0;
    int entregado = 0;
    int rechazado = 0;
    int bloqueado = 0;

    for (var route in routes) {
      try {
        final orders = await widget.odooClient.fetchRouteOrders(
          token: widget.token,
          routeId: route.id,
        );

        for (var order in orders.orders) {
          switch (order.planningStatus) {
            case 'in_planification':
            case 'pending':
              pendiente++;
              break;
            case 'blocked':
              bloqueado++;
              break;
            case 'in_transport':
              enTransporte++;
              break;
            case 'start_of_route':
              enCurso++;
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
      'enTransporte': enTransporte,
      'enCurso': enCurso,
      'entregado': entregado,
      'rechazado': rechazado,
      'bloqueado': bloqueado,
    };
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(responsive.getResponsiveSize(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SedeHeader(
                  formattedDate: _getFormattedDate(),
                ),
                SizedBox(height: responsive.getResponsiveSize(5)),
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
                      padding: EdgeInsets.all(responsive.getResponsiveSize(20)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(responsive.borderRadius),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: responsive.screenWidth < 300
                          ? Column(
                              children: [
                                PieChartWidget(
                                  title: 'Estados de rutas',
                                  data: [
                                    ChartData(
                                      'Por validar',
                                      routeStats['por_validar'] ?? 0,
                                      const Color(0xFFF59E0B),
                                    ),
                                    ChartData(
                                      'En ruta',
                                      routeStats['en_ruta'] ?? 0,
                                      const Color(0xFF3B82F6),
                                    ),
                                    ChartData(
                                      'Terminado',
                                      routeStats['terminado'] ?? 0,
                                      const Color(0xFF10B981),
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsive.getResponsiveSize(20)),
                                FutureBuilder<Map<String, int>>(
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
                                          'Bloqueado',
                                          orderStats['bloqueado'] ?? 0,
                                          const Color(0xFF8B5CF6),
                                        ),
                                        ChartData(
                                          'Transporte',
                                          orderStats['enTransporte'] ?? 0,
                                          const Color(0xFF3B82F6),
                                        ),
                                        ChartData(
                                          'En curso',
                                          orderStats['enCurso'] ?? 0,
                                          const Color(0xFFFCD34D),
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
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: PieChartWidget(
                                    title: 'Estados de rutas',
                                    data: [
                                      ChartData(
                                        'Por validar',
                                        routeStats['por_validar'] ?? 0,
                                        const Color(0xFFF59E0B),
                                      ),
                                      ChartData(
                                        'En ruta',
                                        routeStats['en_ruta'] ?? 0,
                                        const Color(0xFF3B82F6),
                                      ),
                                      ChartData(
                                        'Terminado',
                                        routeStats['terminado'] ?? 0,
                                        const Color(0xFF10B981),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: responsive.getResponsiveSize(20)),
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
                                            'Bloqueado',
                                            orderStats['bloqueado'] ?? 0,
                                            const Color(0xFF8B5CF6),
                                          ),
                                          ChartData(
                                            'Transporte',
                                            orderStats['enTransporte'] ?? 0,
                                            const Color(0xFF3B82F6),
                                          ),
                                          ChartData(
                                            'En curso',
                                            orderStats['enCurso'] ?? 0,
                                            const Color(0xFFFCD34D),
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
                SizedBox(height: responsive.getResponsiveSize(32)),
                // Routes section
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.getResponsiveSize(14),
                    horizontal: responsive.getResponsiveSize(18),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF8FAFC),
                        const Color(0xFFFFFFFF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.route,
                            size: responsive.iconSize,
                            color: const Color(0xFF3B82F6),
                          ),
                          SizedBox(width: responsive.getResponsiveSize(10)),
                          Text(
                            'Rutas de hoy',
                            style: TextStyle(
                              fontSize: responsive.headingMediumFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.getResponsiveSize(10),
                          vertical: responsive.getResponsiveSize(6),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(responsive.borderRadius - 4),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort,
                              size: responsive.iconSize * 0.7,
                              color: const Color(0xFF64748B),
                            ),
                            SizedBox(width: responsive.getResponsiveSize(6)),
                            Text(
                              'Por inicio',
                              style: TextStyle(
                                fontSize: responsive.bodySmallFontSize,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.getResponsiveSize(20)),
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
                                onTapDetail: () async {
                                  await Navigator.push(
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
                                  // Recargar datos al regresar
                                  if (mounted) {
                                    setState(() {
                                      _routesFuture = widget.odooClient.fetchTodayRoutes(widget.token);
                                    });
                                  }
                                },
                              ),
                              if (entry.key < routes.length - 1)
                                SizedBox(height: responsive.getResponsiveSize(16)),
                            ],
                          );
                        }),
                        SizedBox(height: responsive.getResponsiveSize(24)),
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