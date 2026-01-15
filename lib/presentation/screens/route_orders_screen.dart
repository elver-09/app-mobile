import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import '../widgets/route_orders/route_order_card.dart';

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

class _RouteOrdersScreenState extends State<RouteOrdersScreen> {
  late Future<List<OrderItem>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = widget.odooClient.fetchRouteOrders(
      token: widget.token,
      routeId: widget.routeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<OrderItem>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final orders = snapshot.data ?? [];
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
                        const Text(
                          'Listado de órdenes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Secuencia optimizada actual',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Orders list
                    Column(
                      children: [
                        ...orders.asMap().entries.map((entry) {
                          final order = entry.value;
                          return Column(
                            children: [
                              RouteOrderCard(
                                order: order,
                                token: widget.token,
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
