import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import '../widgets/route_orders/route_order_card.dart';
import '../widgets/route_orders/orders_filter_switch.dart';
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
  bool _showOnlyActive = true;
  bool _isLoadingNextOrder = false;

  /// Verifica si TODAS las órdenes están pendientes
  Future<bool> _allOrdersArePending() async {
    try {
      final response = await widget.odooClient.fetchRouteOrders(
        token: widget.token,
        routeId: widget.routeId,
      );

      if (response.orders.isEmpty) return false;

      // Verificar si todas las órdenes están en estado pending
      final allPending = response.orders.every((order) {
        return order.planningStatus == 'pending';
      });

      return allPending;
    } catch (e) {
      print('❌ Error verificando órdenes pendientes: $e');
      return false;
    }
  }

  
  // The _hasStartedOrders method has been removed as it was unused.

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
    if (!mounted) return;
    setState(() {
      _ordersFuture = widget.odooClient.fetchRouteOrders(
        token: widget.token,
        routeId: widget.routeId,
      );
    });
  }

  /// Inicia la ruta de la siguiente orden pendiente
  Future<void> _goToNextOrder() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNextOrder = true;
    });

    try {
      // Llamar al endpoint para iniciar la siguiente orden (la más cercana)
      final result = await widget.odooClient.startNextOrder(
        token: widget.token,
        routeId: widget.routeId,
      );

      if (result['success'] == true) {
        print('✅ Ruta iniciada: ${result["order_number"]}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ruta iniciada: ${result["order_number"]}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Recargar la lista de órdenes para ver el cambio de estado
          _reloadOrders();
        }
      } else {
        print('❌ Error al iniciar ruta: ${result["error"]}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result["error"] ?? "Desconocido"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error iniciando siguiente orden: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNextOrder = false;
        });
      }
    }
  }

    /// Inicia la ruta (primera orden pendiente)
    Future<void> _startRoute() async {
      if (!mounted) return;
      setState(() {
        _isLoadingNextOrder = true;
      });

      try {
        final result = await widget.odooClient.startNextOrder(
          token: widget.token,
          routeId: widget.routeId,
        );

        if (result['success'] == true) {
          print('✅ Ruta iniciada: ${result["order_number"]}');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ruta iniciada: ${result["order_number"]}'),
                backgroundColor: Colors.green,
              ),
            );

            _reloadOrders();
          }
        } else {
          print('❌ Error al iniciar ruta: ${result["error"]}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result["error"] ?? "Desconocido"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error iniciando ruta: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingNextOrder = false;
          });
        }
      }
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
      body: FutureBuilder<RouteOrdersResponse>(
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
          
          // Filtrar órdenes
          final filteredOrders = _showOnlyActive
              ? orders.where((order) {
                  final status = order.planningStatus;
                  return status == 'pending' || status == 'start_of_route';
                }).toList()
              : orders;
          
          return SafeArea(
            child: SingleChildScrollView(
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
                    const SizedBox(height: 1),
                    
                    // Switch de filtro
                    OrdersFilterSwitch(
                      onFilterChanged: (showOnlyActive) {
                        if (mounted) {
                          setState(() {
                            _showOnlyActive = showOnlyActive;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 1),
                    
                    // Orders list
                    if (filteredOrders.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            _showOnlyActive
                                ? 'No hay órdenes pendientes'
                                : 'No hay órdenes en esta ruta',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ...filteredOrders.asMap().entries.map((entry) {
                            final order = entry.value;
                            final isOrderActive =
                              order.planningStatus == 'start_of_route';
                            final isOrderDisabled = false;
                            
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
                                if (entry.key < filteredOrders.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _allOrdersArePending(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Si todas las órdenes están pendientes, mostrar "Iniciar Ruta"
            if (snapshot.data == true) {
              return FloatingActionButton.extended(
                onPressed: _isLoadingNextOrder ? null : _startRoute,
                backgroundColor: Colors.green,
                icon: _isLoadingNextOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow, size: 20, color: Colors.white),
                label: Text(
                  _isLoadingNextOrder ? 'Iniciando...' : 'Iniciar Ruta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            } else {
              // Si hay órdenes iniciadas, mostrar "Siguiente Orden"
              return FloatingActionButton.extended(
                onPressed: _isLoadingNextOrder ? null : _goToNextOrder,
                backgroundColor: const Color(0xFF3B82F6),
                icon: _isLoadingNextOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                label: Text(
                  _isLoadingNextOrder ? 'Cargando...' : 'Siguiente Orden',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            }
          }
          // Mientras se carga, mostrar "Siguiente Orden" por defecto
          return FloatingActionButton.extended(
            onPressed: _isLoadingNextOrder ? null : _goToNextOrder,
            backgroundColor: const Color(0xFF3B82F6),
            icon: const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
            label: const Text(
              'Siguiente Orden',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }
}