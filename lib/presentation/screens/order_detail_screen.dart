import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';

// Core services
import '../../core/services/photo_storage_service.dart';
import '../../core/services/maps_service.dart';
import '../../core/services/photo_converter_service.dart';

// Widgets
import '../widgets/order_detail/order_info_card.dart';
import '../widgets/order_detail/delivery_photos_widget.dart';
import '../widgets/order_detail/photo_view_dialog.dart';
import '../widgets/order_detail/delivery_status_buttons.dart';
import '../widgets/order_detail/reject_order_modal.dart';
import '../widgets/order_detail/delivery_confirmation_modal.dart';

// Odoo client
import '../../core/odoo/odoo_client.dart';
import '../../core/odoo/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String clientName;
  final String phone;
  final String address;
  final String product;
  final String district;
  final String token;
  final OdooClient odooClient;
  final String? routeName;
  final String? fleetType;
  final String? fleetLicense;
  final double? routeStartLatitude;
  final double? routeStartLongitude;
  final double? latitude;
  final double? longitude;
  final String planningStatus;
  final int routeId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.clientName,
    required this.phone,
    required this.address,
    required this.product,
    required this.district,
    required this.token,
    required this.odooClient,
    this.routeName,
    this.fleetType,
    this.fleetLicense,
    this.routeStartLatitude,
    this.routeStartLongitude,
    this.latitude,
    this.longitude,
    this.planningStatus = 'pending',
    this.routeId = 0,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with WidgetsBindingObserver {
  GoogleMapController? routeMapController;

  final String GOOGLE_MAPS_API_KEY = 'AIzaSyCxTlk0WgcQzu_Odxmk2ROu6peiUOX-8Wk';

  List<LatLng> routePoints = [];
  bool isLoadingRoute = true;
  List<File> deliveryPhotos = [];

  // Estado actual de la orden
  late String currentOrderStatus;
  bool _isLoadingNextOrder = false;
  
  // Controller para el campo de comentario
  final TextEditingController _commentController = TextEditingController();

  Timer? _autoRefreshTimer;
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializar con el estado actual de la orden
    currentOrderStatus = widget.planningStatus;
    print(
      '📍 OrderDetailScreen - Origen: (${widget.routeStartLatitude}, ${widget.routeStartLongitude}), Destino: (${widget.latitude}, ${widget.longitude})',
    );
    _getRoutePoints();
    _loadSavedPhotos();
    // Actualizar estado desde servidor
    _refreshOrderStatus();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshOrderStatus(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOrderStatus();
    }
  }

  Future<void> _refreshOrderStatus() async {
    try {
      final details = await widget.odooClient.fetchOrderDetail(
        token: widget.token,
        orderId: widget.orderId,
      );
      if (details != null && mounted) {
        setState(() {
          currentOrderStatus = details.planningStatus;
        });
      }
    } catch (e) {
      print('❌ Error actualizando estado de orden: $e');
    }
  }

  Future<void> _loadSavedPhotos() async {
    try {
      final photos = await PhotoStorageService.loadPhotos(
        widget.orderId.toString(),
      );
      final comment = await PhotoStorageService.loadComment(
        widget.orderId.toString(),
      );
      setState(() {
        deliveryPhotos = photos;
        _commentController.text = comment;
      });
      print(
        '📸 Fotos cargadas para orden ${widget.orderId}: ${deliveryPhotos.length}',
      );
      print('📝 Comentario cargado: $comment');
    } catch (e) {
      print('❌ Error al cargar fotos: $e');
    }
  }

  Future<void> _savePhotos() async {
    try {
      await PhotoStorageService.savePhotoPaths(
        widget.orderId.toString(),
        deliveryPhotos,
      );
      await PhotoStorageService.saveComment(
        widget.orderId.toString(),
        _commentController.text,
      );
      print(
        '💾 Fotos guardadas para orden ${widget.orderId}: ${deliveryPhotos.length}',
      );
      print('💾 Comentario guardado: ${_commentController.text}');
    } catch (e) {
      print('❌ Error al guardar fotos: $e');
    }
  }

  Future<void> _getRoutePoints() async {
    // Validar que tengamos todas las coordenadas necesarias
    if (widget.routeStartLatitude == null || 
        widget.routeStartLongitude == null || 
        widget.latitude == null || 
        widget.longitude == null) {
      print('⚠️ Coordenadas incompletas, usando ruta simple');
      _useFallbackRoute();
      return;
    }
    
    try {
      final String url =
          'https://router.project-osrm.org/route/v1/driving/${widget.routeStartLongitude},${widget.routeStartLatitude};${widget.longitude},${widget.latitude}?overview=full&geometries=geojson';

      print('🔗 Llamando API: $url');
      final response = await http.get(Uri.parse(url));

      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final code = json['code'];

        print('✅ Status API: $code');

        if (code == 'Ok') {
          final routes = json['routes'] as List;

          if (routes.isNotEmpty) {
            final geometry = routes[0]['geometry'];
            final coordinates = geometry['coordinates'] as List;

            print('📍 Coordenadas obtenidas: ${coordinates.length}');

            final decodedPoints = coordinates.map((coord) {
              return LatLng(coord[1] as double, coord[0] as double);
            }).toList();

            setState(() {
              routePoints = decodedPoints;
              isLoadingRoute = false;
            });

            _fitRouteBounds();

            print('✅ Ruta obtenida con ${decodedPoints.length} puntos');
            for (var i = 0; i < decodedPoints.length && i < 5; i++) {
              print('   Punto $i: ${decodedPoints[i]}');
            }
          } else {
            throw Exception('No routes found');
          }
        } else {
          print('❌ API Error: $code');
          print('Message: ${json['message']}');
          _useFallbackRoute();
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        _useFallbackRoute();
      }
    } catch (e) {
      print('❌ Exception: $e');
      _useFallbackRoute();
    }
  }

  void _useFallbackRoute() {
    setState(() {
      // Crear una línea recta entre inicio y fin si hay coordenadas
      if (widget.routeStartLatitude != null && 
          widget.routeStartLongitude != null &&
          widget.latitude != null && 
          widget.longitude != null) {
        routePoints = [
          LatLng(widget.routeStartLatitude!, widget.routeStartLongitude!),
          LatLng(widget.latitude!, widget.longitude!),
        ];
      } else {
        routePoints = []; // Sin ruta si no hay coordenadas
      }
      isLoadingRoute = false;
    });
    print('👍 Usando ruta directa (fallback)');
    _fitRouteBounds();
  }

  Future<void> _removePhoto(int index) async {
    setState(() {
      deliveryPhotos.removeAt(index);
    });
    await _savePhotos();
  }

  void _showPhotosDialog() {
    if (deliveryPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay fotos para mostrar')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PhotoViewDialog(
        photos: deliveryPhotos,
        onDeletePhoto: (index) {
          setState(() {
            _removePhoto(index);
          });
        },
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    print('🔵 Intentando llamar a: $phoneNumber');
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      print('✅ Llamada iniciada correctamente');
    } catch (e) {
      print('❌ Error al iniciar la llamada: $e');
    }
  }

  bool _isOrderCompleted() {
    return currentOrderStatus == 'delivered' ||
        currentOrderStatus == 'cancelled' ||
        currentOrderStatus == 'anulled' ||
        currentOrderStatus == 'returned' ||
        currentOrderStatus == 'cancelled_origin' ||
        currentOrderStatus == 'hand_to_hand';
  }

  bool _isPending() {
    return currentOrderStatus == 'pending';
  }

  Future<bool> _isFirstOrderToStart() async {
    try {
      // Solo mostrar el botón si la orden está en pending
      if (!_isPending()) {
        return false;
      }

      // Obtener todas las órdenes de la ruta
      final response = await widget.odooClient.fetchRouteOrders(
        token: widget.token,
        routeId: widget.routeId,
      );

      // Verificar si hay alguna orden ya en curso
      bool hasStartedOrCompleted = response.orders.any((order) {
        final status = order.planningStatus;
        return status == 'start_of_route' ||
            status == 'delivered' ||
            status == 'cancelled' ||
            status == 'anulled' ||
            status == 'returned' ||
            status == 'cancelled_origin' ||
            status == 'hand_to_hand';
      });

      // Si hay una orden iniciada o completada, no mostrar el botón
      if (hasStartedOrCompleted) {
        return false;
      }

      // Obtener órdenes pendientes
      final pendingOrders = response.orders.where(
        (order) => order.planningStatus == 'pending'
      ).toList();

      if (pendingOrders.isEmpty) {
        return false;
      }

      // Calcular distancias al punto de recojo para todas las órdenes pendientes
      double getDistance(OrderItem order) {
        if (widget.routeStartLatitude == null ||
            widget.routeStartLongitude == null ||
            order.latitude == null ||
            order.longitude == null) {
          return double.maxFinite;
        }

        // Haversine
        const earthRadiusKm = 6371.0;
        final dLat = _toRadians(order.latitude! - widget.routeStartLatitude!);
        final dLon = _toRadians(order.longitude! - widget.routeStartLongitude!);
        final a = (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_toRadians(widget.routeStartLatitude!)) *
                cos(_toRadians(order.latitude!)) *
                sin(dLon / 2) *
                sin(dLon / 2);
        final c = 2 * asin(sqrt(a));
        return earthRadiusKm * c;
      }

      // Encontrar la orden más cercana
      OrderItem closestOrder = pendingOrders.first;
      double minDistance = getDistance(closestOrder);

      for (var order in pendingOrders.skip(1)) {
        double distance = getDistance(order);
        if (distance < minDistance) {
          minDistance = distance;
          closestOrder = order;
        }
      }

      // Retornar true si esta es la orden más cercana
      return closestOrder.id == widget.orderId;
    } catch (e) {
      print('❌ Error verificando si es primera orden: $e');
      return false;
    }
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  Future<bool> _isLastCompletedOrder() async {
    try {
      // Obtener todas las órdenes de la ruta
      final response = await widget.odooClient.fetchRouteOrders(
        token: widget.token,
        routeId: widget.routeId,
      );

      // Verificar si hay alguna orden en curso
      bool hasOrderInProgress = response.orders.any(
        (order) => order.planningStatus == 'start_of_route'
      );

      // Si hay una orden en curso, no mostrar el botón
      if (hasOrderInProgress) {
        return false;
      }

      // Buscar la última orden completada
      OrderItem? lastCompleted;
      for (var order in response.orders.reversed) {
        if (order.planningStatus == 'delivered' ||
            order.planningStatus == 'cancelled' ||
            order.planningStatus == 'anulled' ||
            order.planningStatus == 'returned' ||
            order.planningStatus == 'cancelled_origin' ||
            order.planningStatus == 'hand_to_hand') {
          lastCompleted = order;
          break;
        }
      }

      // Retornar true si esta es la última orden completada
      return lastCompleted?.id == widget.orderId;
    } catch (e) {
      print('❌ Error verificando si es última orden completada: $e');
      return false;
    }
  }

  Future<void> _startRoute() async {
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
        print('✅ Ruta iniciada: ${result['order_number']}');
        // Actualizar el estado
        await _refreshOrderStatus();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ruta iniciada: ${result['order_number']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ Error al iniciar ruta: ${result['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error'] ?? 'Desconocido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Exception en _startRoute: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _startNextDelivery() async {
    setState(() {
      _isLoadingNextOrder = true;
    });

    try {
      // Iniciar la siguiente orden desde la ubicación de la orden actual
      final result = await widget.odooClient.startNextOrderFromCurrent(
        token: widget.token,
        currentOrderId: widget.orderId,
        routeId: widget.routeId,
      );

      if (result['success'] == true) {
        final int nextOrderId = result['order_id'] as int? ?? 0;

        if (nextOrderId == 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la siguiente orden'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Obtener detalle completo de la orden siguiente
        final detail = await widget.odooClient.fetchOrderDetail(
          token: widget.token,
          orderId: nextOrderId,
        );

        if (detail != null && mounted) {
          // Usar coordenadas de la orden actual como punto de inicio
          final startLat = widget.latitude ?? result['latitude'] as double?;
          final startLng = widget.longitude ?? result['longitude'] as double?;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navegando a siguiente entrega'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar al detalle de la orden
          Navigator.pushReplacement(
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
                fleetType: widget.fleetType,
                fleetLicense: widget.fleetLicense,
                routeStartLatitude: startLat,
                routeStartLongitude: startLng,
                latitude: detail.latitude,
                longitude: detail.longitude,
                planningStatus: detail.planningStatus,
                routeId: widget.routeId,
              ),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']?.toString() ?? 'No hay más órdenes en ruta'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNextOrder = false;
        });
      }
    }
  }

  Future<void> _openRouteInMaps() async {
    // Validar que tengamos todas las coordenadas
    if (widget.routeStartLatitude == null || 
        widget.routeStartLongitude == null || 
        widget.latitude == null || 
        widget.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se tienen las coordenadas necesarias para mostrar la ruta'),
        ),
      );
      return;
    }
    
    print(
      '🗺️ Abriendo ruta en mapas desde (${widget.routeStartLatitude}, ${widget.routeStartLongitude}) hasta (${widget.latitude}, ${widget.longitude})',
    );

    final bool success = await MapsService.openRouteInMaps(
      originLat: widget.routeStartLatitude!,
      originLng: widget.routeStartLongitude!,
      destinationLat: widget.latitude!,
      destinationLng: widget.longitude!,
      destinationLabel: widget.clientName,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la aplicación de mapas'),
        ),
      );
    }
  }

  void _onRouteMapCreated(GoogleMapController controller) {
    routeMapController = controller;
    print('🛣️ Mapa de ruta creado');
    _fitRouteBounds();
  }

  void _fitRouteBounds() {
    if (routeMapController == null || routePoints.isEmpty) {
      return;
    }

    double? minLat, maxLat, minLng, maxLng;
    for (final point in routePoints) {
      minLat = minLat == null ? point.latitude : (point.latitude < minLat ? point.latitude : minLat);
      maxLat = maxLat == null ? point.latitude : (point.latitude > maxLat ? point.latitude : maxLat);
      minLng = minLng == null ? point.longitude : (point.longitude < minLng ? point.longitude : minLng);
      maxLng = maxLng == null ? point.longitude : (point.longitude > maxLng ? point.longitude : maxLng);
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    routeMapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 40),
    );
  }

  // Método para obtener el color del estado actual
  Color _getStatusColor() {
    switch (currentOrderStatus) {
      case 'start_of_route':
        return const Color(0xFFF59E0B); // amarillo/naranja - "En curso"
      case 'pending':
        return const Color(0xFF2563EB); // azul - "Pendiente"
      case 'delivered':
        return const Color(0xFF10B981); // verde - "Entregado"
      case 'cancelled':
      case 'anulled':
      case 'returned':
      case 'cancelled_origin':
        return const Color(
          0xFFEF4444,
        ); // rojo - "Rechazado" (por compatibilidad)
      case 'unavailable':
        return const Color(0xFFF97316); // naranja - "No disponible"
      default:
        return const Color(0xFF9CA3AF); // gris por defecto
    }
  }

  // Método para obtener la etiqueta del estado actual
  String _getStatusLabel() {
    switch (currentOrderStatus) {
      case 'start_of_route':
        return 'En curso';
      case 'pending':
        return 'Pendiente';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
      case 'anulled':
      case 'returned':
      case 'cancelled_origin':
        return 'Rechazado'; // Por compatibilidad
      case 'unavailable':
        return 'No disponible';
      default:
        return 'Pendiente';
    }
  }

  Future<void> _showRejectModal() async {
    print('🔴 Abriendo modal de rechazo...');

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print('🔴 Construyendo RejectOrderModal');
        return RejectOrderModal(
          orderNumber: widget.orderNumber,
          clientName: widget.clientName,
        );
      },
    );

    print('🔴 Modal cerrado con resultado: $result');

    if (result != null && mounted) {
      // Aquí puedes procesar los datos del rechazo
      print('🔴 Orden rechazada:');
      print('   Motivo: ${result['reason']}');
      print('   Comentario: ${result['comment']}');
      print('   Fotos: ${result['photos'].length}');

      // Mostrar indicador de envío
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Sincronizando con Odoo...'),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        // Convertir fotos a base64
        final photoBase64 = await PhotoConverterService.filesToBase64(
          result['photos'] as List<File>,
        );

        // Enviar a Odoo
        final success = await widget.odooClient.updateOrderRejected(
          token: widget.token,
          orderId: widget.orderId,
          reason: result['reason'] ?? '',
          comment: result['comment'] ?? '',
          photoBase64List: photoBase64,
        );

        if (mounted) {
          if (success) {
            // Agregar fotos del modal a deliveryPhotos
            setState(() {
              deliveryPhotos.addAll(result['photos'] as List<File>);
              currentOrderStatus = 'cancelled'; // Actualizar estado a rechazado
              _commentController.text = 'Recibido por: ${result['recipient']}';              // Si es "Otro motivo", mostrar el comentario; si no, mostrar la razón
              if (result['reason'] == 'Otro motivo') {
                _commentController.text = 'Motivo: ${result['comment']}';
              } else {
                _commentController.text = 'Motivo: ${result['reason']}';
              }
            });
            await _savePhotos();
            
            // Refrescar estado desde servidor
            await Future.delayed(const Duration(milliseconds: 500));
            await _refreshOrderStatus();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Orden rechazada y sincronizada con Odoo'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
            if (mounted) {
              Navigator.pop(context, {'updated': true});
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '❌ Error al sincronizar con Odoo. Intenta de nuevo.',
                ),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error en _showRejectModal: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeliveryModal() async {
    print('🟢 Abriendo modal de entrega...');

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print('🟢 Construyendo DeliveryConfirmationModal');
        return DeliveryConfirmationModal(
          orderNumber: widget.orderNumber,
          clientName: widget.clientName,
        );
      },
    );

    print('🟢 Modal cerrado con resultado: $result');

    if (result != null && mounted) {
      // Aquí puedes procesar los datos de entrega
      print('🟢 Orden entregada:');
      print('   Fotos: ${result['photos'].length}');
      print('   Receptor: ${result['recipient']}');

      // Mostrar indicador de envío
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Sincronizando con Odoo...'),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        // Convertir fotos a base64
        final photoBase64 = await PhotoConverterService.filesToBase64(
          result['photos'] as List<File>,
        );

        // Enviar a Odoo
        final success = await widget.odooClient.updateOrderDelivered(
          token: widget.token,
          orderId: widget.orderId,
          recipientName: result['recipient'] ?? '',
          photoBase64List: photoBase64,
        );

        if (mounted) {
          if (success) {
            // Agregar fotos del modal a deliveryPhotos
            setState(() {
              deliveryPhotos.addAll(result['photos'] as List<File>);
              currentOrderStatus = 'delivered'; // Actualizar estado a entregado
              // Mostrar nombre del receptor en comentario
              _commentController.text = 'Recibido por: ${result['recipient']}';
            });
            await _savePhotos();
            
            // Refrescar estado desde servidor
            await Future.delayed(const Duration(milliseconds: 500));
            await _refreshOrderStatus();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Orden entregada y sincronizada con Odoo'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            if (mounted) {
              Navigator.pop(context, {'updated': true});
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '❌ Error al sincronizar con Odoo. Intenta de nuevo.',
                ),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error en _showDeliveryModal: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detalle de la orden',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Hoy · ${widget.routeName ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Vehículo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.fleetType ?? ''} · ${widget.fleetLicense ?? ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Order details card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order info card
                    OrderInfoCard(
                      orderNumber: widget.orderNumber,
                      clientName: widget.clientName,
                      phone: widget.phone,
                      address: widget.address,
                      district: widget.district,
                      product: widget.product,
                      onCallPressed: () => _makePhoneCall(widget.phone),
                      onMapPressed: _openRouteInMaps,
                      statusLabel: _getStatusLabel(),
                      statusColor: _getStatusColor(),
                    ),
                    const SizedBox(height: 24),
                    // Location section
                    const Text(
                      'Ubicación de entrega',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Map preview - Full width
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        child: (widget.routeStartLatitude == null || 
                                widget.routeStartLongitude == null ||
                                widget.latitude == null || 
                                widget.longitude == null)
                            ? Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Text(
                                    'Coordenadas no disponibles',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : GoogleMap(
                                onMapCreated: _onRouteMapCreated,
                                gestureRecognizers: {
                                  Factory<OneSequenceGestureRecognizer>(
                                    () => EagerGestureRecognizer(),
                                  ),
                                },
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    (widget.routeStartLatitude! + widget.latitude!) / 2,
                                    (widget.routeStartLongitude! + widget.longitude!) / 2,
                                  ),
                                  zoom: 14.0,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('route_start'),
                                    position: LatLng(widget.routeStartLatitude!, widget.routeStartLongitude!),
                                    infoWindow: const InfoWindow(title: 'Inicio'),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueGreen,
                                    ),
                                  ),
                                  Marker(
                                    markerId: const MarkerId('route_end'),
                                    position: LatLng(
                                      widget.latitude!,
                                      widget.longitude!,
                                    ),
                                    infoWindow: const InfoWindow(title: 'Destino'),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                  ),
                                },
                                polylines: {
                                  Polyline(
                                    polylineId: const PolylineId('route'),
                                    color: const Color(0xFF2563EB),
                                    width: 3,
                                    points: isLoadingRoute
                                        ? [
                                            LatLng(widget.routeStartLatitude!, widget.routeStartLongitude!),
                                            LatLng(widget.latitude!, widget.longitude!),
                                          ]
                                        : routePoints,
                                  ),
                                },
                                zoomGesturesEnabled: false,
                                scrollGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                          zoomControlsEnabled: true,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Delivery status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estado de la entrega',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Text(
                          'Elige solo una opción',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status buttons
                    DeliveryStatusButtons(
                      onEntregadoPressed: _showDeliveryModal,
                      onRechazadoPressed: _showRejectModal,
                    ),
                    const SizedBox(height: 24),
                    // Widget de fotos
                    DeliveryPhotosWidget(
                      photos: deliveryPhotos,
                      maxPhotos: 2,
                      onViewPhotos: _showPhotosDialog,
                      onRemovePhoto: _removePhoto,
                    ),
                    const SizedBox(height: 16),
                    // Comment field
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Comentario para la central y el cliente\n(opcional)',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Botón Iniciar ruta (solo para la primera orden más cercana)
                    if (_isPending())
                      FutureBuilder<bool>(
                        future: _isFirstOrderToStart(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          
                          if (snapshot.data == true) {
                            return Center(
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingNextOrder ? null : _startRoute,
                                icon: _isLoadingNextOrder
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.route),
                                label: const Text('Iniciar ruta'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    
                    if (_isPending())
                      const SizedBox(height: 24),
                    
                    // Botón Iniciar siguiente entrega (solo cuando la orden está completada y es la última)
                    if (_isOrderCompleted())
                      FutureBuilder<bool>(
                        future: _isLastCompletedOrder(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          
                          if (snapshot.data == true) {
                            return Center(
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingNextOrder ? null : _startNextDelivery,
                                icon: _isLoadingNextOrder
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.navigate_next),
                                label: const Text('Iniciar siguiente entrega'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          return const SizedBox.shrink();
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
