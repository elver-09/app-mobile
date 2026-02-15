import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/screens/scan_barcode_screen.dart';
import '../widgets/route_orders/route_order_card.dart';
import '../widgets/route_orders/orders_filter_switch.dart';
import '../widgets/route_orders/route_verification_header.dart';
import '../widgets/route_orders/start_optimized_route_dialog.dart';
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
          final unscannedCount = result['unscanned_count'] ?? 0;
          final message = unscannedCount > 0
              ? 'Ruta iniciada: ${result["order_number"]}\n⚠️ $unscannedCount orden${unscannedCount > 1 ? 'es' : ''} sin escanear registrada${unscannedCount > 1 ? 's' : ''}'
              : 'Ruta iniciada: ${result["order_number"]}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: unscannedCount > 0 ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 4),
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

  void _showStartOptimizedRouteDialog(List<OrderItem> allOrders) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StartOptimizedRouteDialog(
          orders: allOrders,
          onStartRoute: () {
            _startRoute();
          },
        );
      },
    );
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
    final responsive = context.responsive;
    
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
                  return status == 'in_planification' || 
                        status == 'in_transport' || 
                        status == 'start_of_route';
                }).toList()
              : orders;

          // Verificar si todas las órdenes están escaneadas (en_transporte o posterior)
          final allOrdersScanned = orders.every((order) {
            return order.planningStatus != 'in_planification';
          });
          
          // Verificar si la ruta ya está en curso
          final routeInProgress = response.routeStatus == 'in_route';

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(responsive.getResponsiveSize(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button + title
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
                        SizedBox(width: responsive.getResponsiveSize(8)),
                        Text(
                          allOrdersScanned ? 'Órdenes asignadas' : 'Verificar carga',
                          style: TextStyle(
                            fontSize: responsive.headingMediumFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.getResponsiveSize(1)),

                    // Route Verification Header Widget - Mostrar hasta que todas estén escaneadas
                    if (!allOrdersScanned) ...[
                      RouteVerificationHeader(
                        routeName: widget.routeName,
                        fleetType: fleetType,
                        fleetLicense: fleetLicense,
                        orders: orders,
                        routeStatus: response.routeStatus,
                        onScanTap: () async {
                        print('🔵 Navegando al scanner...');
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanBarcodeScreen(
                              routeName: widget.routeName,
                              fleetType: fleetType,
                              fleetLicense: fleetLicense,
                              orders: orders,
                              odooClient: widget.odooClient,
                              token: widget.token,
                            ),
                          ),
                        );
                        
                        print('🔵 Regresó del scanner con resultado: $result');
                        // Si regresó con true, refrescar la lista
                        if (result == true && mounted) {
                          print('🔵 Esperando 2 segundos para que Odoo procese el cambio...');
                          await Future.delayed(const Duration(seconds: 2));
                          print('🔵 Llamando a _reloadOrders() para refrescar...');
                          _reloadOrders();
                        }
                      },
                    ),
                    ],
                    SizedBox(height: responsive.getResponsiveSize(24)),

                    // Órdenes asignadas title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Órdenes asignadas',
                          style: TextStyle(
                            fontSize: responsive.bodyMediumFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${orders.length} órdenes · ${orders.where((o) => o.planningStatus == 'in_planification').length} por escanear',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: responsive.bodySmallFontSize,
                              color: const Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.getResponsiveSize(12)),

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
                    SizedBox(height: responsive.getResponsiveSize(12)),

                    // Orders list
                    if (filteredOrders.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: responsive.getResponsiveSize(32)),
                          child: Text(
                            _showOnlyActive
                                ? 'No hay órdenes pendientes'
                                : 'No hay órdenes en esta ruta',
                            style: TextStyle(
                              fontSize: responsive.bodyMediumFontSize,
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
                                  SizedBox(height: responsive.getResponsiveSize(12)),
                              ],
                            );
                          }),
                          SizedBox(height: responsive.getResponsiveSize(20)),
                          if (!allOrdersScanned && !routeInProgress) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: responsive.getResponsiveSize(16)),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                                    onTap: () => _showStartOptimizedRouteDialog(orders),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: responsive.getResponsiveSize(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.route,
                                            color: Colors.white,
                                            size: responsive.iconSize,
                                          ),
                                          SizedBox(width: responsive.getResponsiveSize(10)),
                                          Text(
                                            'Iniciar ruta optimizada',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: responsive.bodyMediumFontSize,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: responsive.getResponsiveSize(16)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: responsive.getResponsiveSize(16)),
                              child: Text(
                                'Puedes iniciar la ruta aunque queden órdenes sin validar. Recuerda validar toda la carga antes de salir.',
                                style: TextStyle(
                                  fontSize: responsive.bodySmallFontSize,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: responsive.getResponsiveSize(20)),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: StreamBuilder<RouteOrdersResponse?>(
        stream: Stream.periodic(const Duration(seconds: 2), (_) async {
          return await widget.odooClient.fetchRouteOrders(
            token: widget.token,
            routeId: widget.routeId,
          );
        }).asyncExpand((future) => Stream.fromFuture(future)),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final orders = snapshot.data!.orders;
            final routeStatus = snapshot.data!.routeStatus;
            
            // Si la ruta ya está terminada, no mostrar botón
            if (routeStatus == 'finished') {
              return const SizedBox.shrink();
            }
            
            // Verificar si hay órdenes en curso (start_of_route)
            final hasOrdersInCourse = orders.any((order) => order.planningStatus == 'start_of_route');

            // Verificar si todas las órdenes están en transporte (in_transport)
            final allOrdersInTransport = orders.every((order) =>
              order.planningStatus == 'in_transport');

            // Verificar si hay órdenes entregadas o rechazadas
            final hasOrdersDeliveredOrRejected = orders.any((order) {
              return order.planningStatus == 'delivered' ||
                order.planningStatus == 'cancelled' ||
                order.planningStatus == 'anulled' ||
                order.planningStatus == 'returned' ||
                order.planningStatus == 'cancelled_origin';
            });

            // Si no hay órdenes en curso y todas están en transporte, mostrar "Iniciar Ruta"
            if (!hasOrdersInCourse && allOrdersInTransport) {
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
                    : const Icon(
                        Icons.play_arrow,
                        size: 20,
                        color: Colors.white,
                      ),
                label: Text(
                  _isLoadingNextOrder ? 'Iniciando...' : 'Iniciar Ruta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            }

            // Si hay órdenes en curso o entregadas/rechazadas, mostrar "Siguiente Orden"
            if (hasOrdersInCourse || hasOrdersDeliveredOrRejected) {
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
                    : const Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Colors.white,
                      ),
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
            
            // Sin órdenes en curso ni todas escaneadas, no mostrar nada
            return const SizedBox.shrink();
          }
          
          // Mientras carga, mostrar nada
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
