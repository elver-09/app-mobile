import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import '../widgets/route_orders/route_order_card.dart';
import 'order_detail_screen.dart';

class RouteOrdersScreen extends StatefulWidget {
  final int routeId;
  final String routeName;
  final String token;
  final OdooClient odooClient;

  const RouteOrdersScreen({
    super.key,
    required this.routeId,
    required this.routeName,
    required this.token,
    required this.odooClient,
  });

  @override
  State<RouteOrdersScreen> createState() => _RouteOrdersScreenState();
}

class _RouteOrdersScreenState extends State<RouteOrdersScreen>
    with WidgetsBindingObserver {
  late Future<RouteOrdersResponse> _ordersFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ordersFuture = widget.odooClient.fetchRouteOrders(
      token: widget.token,
      routeId: widget.routeId,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recargar órdenes cuando la pantalla se reanuda
      _reloadOrders();
    }
  }

  void _reloadOrders() {
    setState(() {
      _ordersFuture = widget.odooClient.fetchRouteOrders(
        token: widget.token,
        routeId: widget.routeId,
      );
    });
  }

  Future<void> _openOrderDetail(
    OrderItem order,
    String fleetType,
    String fleetLicense,
    double? routeStartLat,
    double? routeStartLng,
  ) async {
    try {
      print('🔍 Obteniendo detalle de orden ID: ${order.id}');
      // Obtener detalle completo de la orden
      final detail = await widget.odooClient.fetchOrderDetail(
        token: widget.token,
        orderId: order.id,
      );

      if (detail == null) {
        print('❌ El detalle retornó null');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar el detalle de la orden'),
          ),
        );
        return;
      }

      print('✅ Detalle cargado correctamente');
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(
            orderId: detail.id,
            orderNumber: detail.orderNumber,
            clientName: detail.fullname,
            phone: detail.phone ?? '',
            address: detail.address,
            product: detail.product ?? 'N/A',
            district: detail.district,
            token: widget.token,
            odooClient: widget.odooClient,
            routeName: widget.routeName,
            fleetType: fleetType,
            fleetLicense: fleetLicense,
            routeStartLatitude: routeStartLat,
            routeStartLongitude: routeStartLng,
            latitude: detail.latitude,
            longitude: detail.longitude,
            planningStatus: detail.planningStatus,
            routeId: widget.routeId,
          ),
        ),
      );
      if (result is Map && result['updated'] == true) {
        _reloadOrders();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar orden: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<RouteOrdersResponse>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final response = snapshot.data;
            if (response == null) {
              return const Center(child: Text('No hay datos disponibles'));
            }
            final orders = response.orders;
            final fleetType = response.fleetType;
            final fleetLicense = response.fleetLicense;
            final routeStartLat = response.routeStartLatitude;
            final routeStartLng = response.routeStartLongitude;
            
            if (orders.isEmpty) {
              return const Center(child: Text('No hay órdenes en esta ruta'));
            }
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Listado de órdenes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Secuencia optimizada actual',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    const SizedBox(height: 24),
                    // Orders list
                    Column(
                      children: [
                        ...orders.asMap().entries.map((entry) {
                          final order = entry.value;
                            final isOrderActive =
                              order.planningStatus == 'start_of_route';
                            final isOrderCompleted =
                              order.planningStatus == 'delivered' ||
                              order.planningStatus == 'cancelled' ||
                              order.planningStatus == 'anulled' ||
                              order.planningStatus == 'returned' ||
                              order.planningStatus == 'cancelled_origin' ||
                              order.planningStatus == 'hand_to_hand';
                          final isOrderDisabled = !isOrderActive && !isOrderCompleted;
                          
                          return Column(
                            children: [
                              RouteOrderCard(
                                order: order,
                                token: widget.token,
                                odooClient: widget.odooClient,
                                routeName: widget.routeName,
                                onStartRouteSuccess: _reloadOrders,
                                isActive: isOrderActive,
                                isDisabled: isOrderDisabled,
                                routeId: widget.routeId,
                                routeStartLatitude: routeStartLat,
                                routeStartLongitude: routeStartLng,
                                allOrders: orders,
                                onTap: () => _openOrderDetail(
                                  order,
                                  fleetType,
                                  fleetLicense,
                                  routeStartLat,
                                  routeStartLng,
                                ),
                              ),
                              if (entry.key < orders.length - 1)
                                const SizedBox(height: 12),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
