import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:trainyl_2_0/presentation/screens/scan_barcode_screen.dart';
import '../widgets/route_orders/route_order_card.dart';
import '../widgets/route_orders/orders_filter_switch.dart';
import '../widgets/route_orders/route_verification_header.dart';
import '../widgets/route_orders/start_optimized_route_dialog.dart';
import '../widgets/route_orders/grouped_order_card.dart';
import '../widgets/order_detail/partial_delivery_modal.dart';
import '../widgets/order_detail/multiple_delivery_modal.dart';
import '../widgets/order_detail/reprogram_modal.dart';
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
  List<Map<String, dynamic>> rejectionReasons = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ordersFuture = widget.odooClient.fetchRouteOrders(
      token: widget.token,
      routeId: widget.routeId,
    );
    _loadRejectionReasons();
  }

  Future<void> _loadRejectionReasons() async {
    try {
      final reasons = await widget.odooClient.fetchRejectionReasons(
        token: widget.token,
      );
      if (mounted) {
        setState(() {
          rejectionReasons = reasons;
        });
        print('✅ Razones de rechazo cargadas: ${reasons.length}');
      }
    } catch (e) {
      print('❌ Error al cargar razones de rechazo: $e');
    }
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
    // Recargar también las razones de rechazo para que estén siempre actualizadas
    _loadRejectionReasons();
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
          final startedCount = result['started_orders_count'] ?? 1;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                startedCount > 1
                    ? 'Grupo en curso: ${result["order_number"]} ($startedCount órdenes)'
                    : 'Ruta iniciada: ${result["order_number"]}',
              ),
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
          final startedCount = result['started_orders_count'] ?? 1;
          final unscannedCount = result['unscanned_count'] ?? 0;
          final baseMessage = startedCount > 1
              ? 'Grupo en curso: ${result["order_number"]} ($startedCount órdenes)'
              : 'Ruta iniciada: ${result["order_number"]}';
          final message = unscannedCount > 0
              ? '$baseMessage\n⚠️ $unscannedCount orden${unscannedCount > 1 ? 'es' : ''} sin escanear registrada${unscannedCount > 1 ? 's' : ''}'
              : baseMessage;
          
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
            routeSequence: detail.routeSequence ?? detail.sequence ?? order.routeSequence ?? order.sequence,
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

  Widget _buildMixedOrdersList(
    List<OrderItem> allOrders,
    List<OrderItem> filteredOrders,
    List<GroupedOrder> groupedScannedOrders,
    String fleetType,
    String fleetLicense,
    double? routeStartLat,
    double? routeStartLng,
    ResponsiveHelper responsive,
    bool allOrdersScanned,
    bool routeInProgress,
  ) {
    // FILTRAR: Solo mostrar grupos con 2 o más órdenes
    final actualGroups = groupedScannedOrders.where((group) => group.orders.length >= 2).toList();
    
    // Obtener IDs de órdenes que están en grupos REALES (2+ órdenes)
    final groupedOrderIds = actualGroups
        .expand((group) => group.orders)
        .map((order) => order.id)
        .toSet();

    // Filtrar órdenes individuales (no están en grupos de 2+)
    final individualOrders = filteredOrders.where((order) {
      return !groupedOrderIds.contains(order.id);
    }).toList();

    return Column(
      children: [
        // Mostrar SOLO grupos con 2 o más órdenes
        ...actualGroups.map((groupedOrder) {
          // Verificar si todas las órdenes están rechazadas y pueden reprogramarse
          final allRejected = groupedOrder.orders.every((order) => order.planningStatus == 'cancelled');
          bool allCanReprogramAfterRejection = false;
          if (allRejected && rejectionReasons.isNotEmpty) {
            allCanReprogramAfterRejection = groupedOrder.orders.every((order) {
              if (order.reasonRejectionId == null) return false;
              final rejectedReason = rejectionReasons.firstWhere(
                (r) => r['id'] == order.reasonRejectionId,
                orElse: () => {},
              );
              return rejectedReason['reprogramed'] ?? false;
            });
          }

          // Mostrar gestionar cuando exista al menos una orden en curso.
          final inCourseOrders = groupedOrder.orders
              .where((order) => order.planningStatus == 'start_of_route')
              .toList();
          final hasInCourse = inCourseOrders.isNotEmpty;

          // Si el grupo está mixto, gestionar solo las órdenes en curso.
          final manageableGroup = inCourseOrders.length == groupedOrder.orders.length
              ? groupedOrder
              : GroupedOrder(
                  clientName: groupedOrder.clientName,
                  address: groupedOrder.address,
                  phone: groupedOrder.phone,
                  orders: inCourseOrders,
                  latitude: groupedOrder.latitude,
                  longitude: groupedOrder.longitude,
                );

          // Lógica de botones:
          // - Si todas están rechazadas Y pueden reprogramar: mostrar SOLO Reprogramar
          // - Si existe al menos una en curso: mostrar Gestionar
          final showReprogramButton = allRejected && allCanReprogramAfterRejection;
          final showManageButton = !showReprogramButton && hasInCourse;
          final VoidCallback onManageTap = () => _showGroupedOrderOptions(manageableGroup);

          return Column(
            children: [
              GroupedOrderCard(
                groupedOrder: groupedOrder,
                onTap: onManageTap,
                showManageButton: showManageButton,
                showReprogramButton: showReprogramButton,
                onReprogramTap: showReprogramButton ? () => _showReprogramGroupedOrdersModal(groupedOrder) : null,
              ),
              SizedBox(height: responsive.getResponsiveSize(12)),
            ],
          );
        }),
        
        // Mostrar órdenes individuales (no escaneadas o sin grupo)
        ...individualOrders.asMap().entries.map((entry) {
          final order = entry.value;
          final isOrderActive = order.planningStatus == 'start_of_route';
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
                allOrders: allOrders,
                onTap: () => _openOrderDetail(
                  order,
                  fleetType,
                  fleetLicense,
                  routeStartLat,
                  routeStartLng,
                ),
              ),
              if (entry.key < individualOrders.length - 1)
                SizedBox(height: responsive.getResponsiveSize(12)),
            ],
          );
        }),
        SizedBox(height: responsive.getResponsiveSize(8)),
        // Botón de iniciar ruta optimizada (solo si no todas están escaneadas y la ruta no está en progreso)
        if (!allOrdersScanned && !routeInProgress) ...[
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(responsive.borderRadius),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                  onTap: () => _showStartOptimizedRouteDialog(allOrders),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.getResponsiveSize(14),
                      vertical: responsive.getResponsiveSize(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
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
          SizedBox(height: responsive.getResponsiveSize(6)),
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
          SizedBox(height: responsive.getResponsiveSize(8)),
        ],
      ],
    );
  }

  void _showGroupedOrderOptions(GroupedOrder groupedOrder) {
    // Verificar si todas las órdenes están rechazadas
    final allRejected = groupedOrder.orders.every((order) => order.planningStatus == 'cancelled');
    
    print('🔍 _showGroupedOrderOptions: allRejected=$allRejected');
    print('🔍 Total órdenes en grupo: ${groupedOrder.orders.length}');
    print('🔍 Razones de rechazo cargadas: ${rejectionReasons.length}');
    print('🔍 Razones: $rejectionReasons');
    
    // Verificar si TODAS pueden reprogramarse (todas tienen razón y la razón permite reprogramación)
    bool allCanReprogramAfterRejection = false;
    if (allRejected && rejectionReasons.isNotEmpty) {
      allCanReprogramAfterRejection = groupedOrder.orders.every((order) {
        print('🔍 Verificando orden ${order.id}: reasonId=${order.reasonRejectionId}, status=${order.planningStatus}');
        
        if (order.reasonRejectionId == null) {
          print('  ❌ No tiene reasonRejectionId');
          return false;
        }
        
        // Buscar la razón de esta orden
        final rejectedReason = rejectionReasons.firstWhere(
          (r) => r['id'] == order.reasonRejectionId,
          orElse: () => {},
        );
        
        print('  Razón encontrada: $rejectedReason');
        
        // Verificar que el boolean 'reprogramed' esté en true
        final canReprogramThisOrder = rejectedReason['reprogramed'] ?? false;
        print('  canReprogram=$canReprogramThisOrder');
        return canReprogramThisOrder;
      });
    }

    print('🔍 Resultado final: allRejected=$allRejected, allCanReprogramAfterRejection=$allCanReprogramAfterRejection');


    // Si todas están rechazadas Y pueden reprogramarse, mostrar SOLO el botón Reprogramar
    if (allRejected && allCanReprogramAfterRejection) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Todas las órdenes han sido rechazadas',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReprogramGroupedOrdersModal(groupedOrder);
                  },
                  icon: const Icon(Icons.schedule, color: Colors.white),
                  label: const Text('Reprogramar todas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona una acción',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showPartialDeliveryModal(groupedOrder);
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('Entrega parcial'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF93C5FD), width: 1.5),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showMultipleDeliveryModal(groupedOrder, 'deliver');
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Entregar todas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showMultipleDeliveryModal(groupedOrder, 'reject');
                },
                icon: const Icon(Icons.cancel, color: Colors.white),
                label: const Text('Rechazar todas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReprogramGroupedOrdersModal(GroupedOrder groupedOrder) {
    showDialog(
      context: context,
      builder: (_) => const ReprogramModal(),
    ).then((result) async {
      if (result != null && mounted) {
        final date = result['date'] as String?;
        final comment = result['comment'] as String? ?? '';
        
        print('🔄 Reprogramando ${groupedOrder.orders.length} órdenes para: $date');
        
        // Reprogramar todas las órdenes del grupo
        bool allSuccessful = true;
        for (final order in groupedOrder.orders) {
          try {
            final success = await widget.odooClient.reprogramOrder(
              token: widget.token,
              orderId: order.id,
              deliveryDateIso: date ?? DateTime.now().toIso8601String(),
              comment: comment,
            );
            if (!success) {
              allSuccessful = false;
              print('❌ Error al reprogramar orden ${order.id}');
            }
          } catch (e) {
            allSuccessful = false;
            print('❌ Excepción al reprogramar orden ${order.id}: $e');
          }
        }
        
        if (mounted) {
          if (allSuccessful) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${groupedOrder.orders.length} órdenes reprogramadas para: ${date ?? 'N/A'}'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            // Recargar órdenes para reflejar los cambios
            _reloadOrders();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al reprogramar algunas órdenes'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      }
    });
  }

  void _showPartialDeliveryModal(GroupedOrder groupedOrder) {
    showDialog(
      context: context,
      builder: (context) => PartialDeliveryModal(
        groupedOrder: groupedOrder,
        odooClient: widget.odooClient,
        token: widget.token,
      ),
    ).then((result) {
      if (result != null && mounted) {
        _handlePartialDeliveryResult(result);
      }
    });
  }

  void _showMultipleDeliveryModal(GroupedOrder groupedOrder, String actionType) {
    showDialog(
      context: context,
      builder: (context) => MultipleDeliveryModal(
        groupedOrder: groupedOrder,
        actionType: actionType,
        odooClient: widget.odooClient,
        token: widget.token,
      ),
    ).then((result) {
      if (result != null && mounted) {
        _handleMultipleDeliveryResult(result);
      }
    });
  }

  void _handlePartialDeliveryResult(Map<String, dynamic> result) async {
    print('📦 Partial delivery result: $result');
    
    final deliveredOrders = (result['ordersToDeliver'] as List?)
        ?.map((o) => o as OrderItem)
        .toList() ?? [];
    final rejectedOrders = (result['ordersToReject'] as List?)
        ?.map((o) => o as OrderItem)
        .toList() ?? [];
    final deliveryPhotos = (result['deliveryPhotos'] as List?)
        ?.map((p) => p as File)
        .toList() ?? [];
    final rejectionPhotos = (result['rejectionPhotos'] as List?)
        ?.map((p) => p as File)
        .toList() ?? [];
    
    print('✅ Órdenes a entregar: ${deliveredOrders.length}');
    print('✅ Órdenes a rechazar: ${rejectedOrders.length}');
    print('✅ Fotos de entrega: ${deliveryPhotos.length}');
    print('✅ Fotos de rechazo: ${rejectionPhotos.length}');
    
    if (!mounted) return;
    
    try {
      // Procesar entregas
      if (deliveredOrders.isNotEmpty) {
        // Convertir fotos de entrega a base64
        final List<String> deliveryPhotoBase64List = [];
        for (final photo in deliveryPhotos) {
          final bytes = await photo.readAsBytes();
          final base64String = base64Encode(bytes);
          deliveryPhotoBase64List.add(base64String);
        }
        
        final deliveryOrderIds = deliveredOrders.map((o) => o.id).toList();
        final success = await widget.odooClient.updateMultipleDelivered(
          token: widget.token,
          orderIds: deliveryOrderIds,
          recipientName: result['deliveryComment'] as String? ?? 'N/A',
          photoBase64List: deliveryPhotoBase64List,
          deliveryComment: result['deliveryComment'] as String?,
        );
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al sincronizar entregas'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      // Procesar rechazos
      if (rejectedOrders.isNotEmpty) {
        // Convertir fotos de rechazo a base64
        final List<String> rejectionPhotoBase64List = [];
        for (final photo in rejectionPhotos) {
          final bytes = await photo.readAsBytes();
          final base64String = base64Encode(bytes);
          rejectionPhotoBase64List.add(base64String);
        }
        
        final rejectOrderIds = rejectedOrders.map((o) => o.id).toList();
        final success = await widget.odooClient.updateMultipleRejected(
          token: widget.token,
          orderIds: rejectOrderIds,
          reasonId: result['rejectionReason'] as int? ?? 0,
          reason: result['rejectionReasonName'] as String? ?? 'N/A',
          comment: result['rejectionComment'] as String? ?? '',
          photoBase64List: rejectionPhotoBase64List,
        );
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al sincronizar rechazos'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entrega parcial procesada: ${deliveredOrders.length} entregadas, ${rejectedOrders.length} rechazadas'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar órdenes después de procesar
        Future.delayed(const Duration(seconds: 1), _reloadOrders);
      }
    } catch (e) {
      print('❌ Error procesando entrega parcial: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMultipleDeliveryResult(Map<String, dynamic> result) async {
    print('📦 Multiple delivery result: $result');
    
    final type = result['type'] as String;
    final orders = (result['orders'] as List?)
        ?.map((o) => o as OrderItem)
        .toList() ?? [];
    final photos = (result['photos'] as List?)
        ?.map((p) => p as File)
        .toList() ?? [];
    
    print('✅ Tipo: $type');
    print('✅ Órdenes a procesar: ${orders.length}');
    print('✅ Fotos capturadas: ${photos.length}');
    
    if (orders.isEmpty || photos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay datos para procesar'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    if (!mounted) return;
    
    try {
      // Convertir fotos a base64
      final List<String> photoBase64List = [];
      for (final photo in photos) {
        final bytes = await photo.readAsBytes();
        final base64String = base64Encode(bytes);
        photoBase64List.add(base64String);
      }
      
      final orderIds = orders.map((o) => o.id).toList();
      bool success = false;
      
      if (type == 'multiple_delivery') {
        // Entregar todas las órdenes
        success = await widget.odooClient.updateMultipleDelivered(
          token: widget.token,
          orderIds: orderIds,
          recipientName: result['recipient_name'] as String? ?? 'N/A',
          photoBase64List: photoBase64List,
          deliveryComment: result['delivery_comment'] as String?,
        );
      } else if (type == 'multiple_reject') {
        // Rechazar todas las órdenes
        success = await widget.odooClient.updateMultipleRejected(
          token: widget.token,
          orderIds: orderIds,
          reasonId: result['reasonId'] as int? ?? 0,
          reason: result['reason'] as String? ?? 'N/A',
          comment: result['comment'] as String? ?? '',
          photoBase64List: photoBase64List,
        );
      }
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al sincronizar con Odoo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'multiple_delivery'
                ? '${orders.length} órdenes entregadas'
                : '${orders.length} órdenes rechazadas'),
            backgroundColor:
                type == 'multiple_delivery' ? Colors.green : Colors.red,
          ),
        );
        // Recargar órdenes después de procesar
        Future.delayed(const Duration(seconds: 1), _reloadOrders);
      }
    } catch (e) {
      print('❌ Error procesando entrega/rechazo múltiple: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

          // Verificar si hay órdenes escaneadas (en_transporte o posterior)
          final scannedOrders = orders.where((order) {
            return order.planningStatus != 'in_planification';
          }).toList();
          
          // Agrupar órdenes escaneadas por cliente+dirección
          final groupedScannedOrders = scannedOrders.isNotEmpty 
              ? GroupedOrder.groupOrders(scannedOrders)
              : <GroupedOrder>[];
          
          // Mostrar vista agrupada si hay al menos un grupo con múltiples órdenes
          final shouldShowGroupedView = groupedScannedOrders.any((group) => group.orders.length > 1);
          
          // Verificar si TODAS las órdenes están escaneadas (para ocultar el scanner)
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
                    SizedBox(height: responsive.getResponsiveSize(12)),

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
                              fontSize: responsive.bodyMediumFontSize,
                              color: const Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.getResponsiveSize(1)),

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
                    SizedBox(height: responsive.getResponsiveSize(6)),

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
                    else if (shouldShowGroupedView)
                      // Mostrar vista mixta: órdenes agrupadas (escaneadas) + órdenes individuales (no escaneadas)
                      _buildMixedOrdersList(orders, filteredOrders, groupedScannedOrders, fleetType, fleetLicense, routeStartLat, routeStartLng, responsive, allOrdersScanned, routeInProgress)
                    else
                      // Mostrar solo órdenes individuales (ninguna agrupación aún)
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
                            Center(
                              child: Container(
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
                                        horizontal: responsive.getResponsiveSize(14),
                                        vertical: responsive.getResponsiveSize(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                            SizedBox(height: responsive.getResponsiveSize(6)),
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
                            SizedBox(height: responsive.getResponsiveSize(8)),
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
              order.planningStatus == 'in_transport' ||
              order.planningStatus == 'blocked');

            final hasOrdersInTransport = orders.any(
              (order) => order.planningStatus == 'in_transport',
            );

            // Verificar si hay órdenes entregadas o rechazadas
            final hasOrdersDeliveredOrRejected = orders.any((order) {
              return order.planningStatus == 'delivered' ||
                order.planningStatus == 'cancelled' ||
                order.planningStatus == 'anulled' ||
                order.planningStatus == 'returned' ||
                order.planningStatus == 'cancelled_origin' ||
                order.planningStatus == 'blocked';
            });

            // Si no hay órdenes en curso y todas están en transporte, mostrar "Iniciar Ruta"
            if (!hasOrdersInCourse && allOrdersInTransport && hasOrdersInTransport) {
              return Transform.scale(
                scale: 0.88,
                child: FloatingActionButton.extended(
                  onPressed: _isLoadingNextOrder ? null : _startRoute,
                  backgroundColor: Colors.green,
                  icon: _isLoadingNextOrder
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.play_arrow,
                          size: 16,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoadingNextOrder ? 'Iniciando...' : 'Iniciar Ruta',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }

            // Si hay órdenes en curso o entregadas/rechazadas, mostrar "Siguiente Orden"
            if ((hasOrdersInCourse || hasOrdersDeliveredOrRejected) && hasOrdersInTransport) {
              return Transform.scale(
                scale: 0.88,
                child: FloatingActionButton.extended(
                  onPressed: _isLoadingNextOrder ? null : _goToNextOrder,
                  backgroundColor: const Color(0xFF3B82F6),
                  icon: _isLoadingNextOrder
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoadingNextOrder ? 'Cargando...' : 'Siguiente Orden',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
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
