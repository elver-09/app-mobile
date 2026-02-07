import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

// Core services
import '../../core/services/photo_storage_service.dart';
import '../../core/services/maps_service.dart';
import '../../core/services/location_service.dart';
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
    LatLng? _originLatLng;
  List<File> deliveryPhotos = [];
  List<Map<String, dynamic>> rejectionReasons = [];

  // Estado actual de la orden
  late String currentOrderStatus;
  
  // Controller para el campo de comentario
  final TextEditingController _commentController = TextEditingController();

  Timer? _autoRefreshTimer;
  bool _isAppInBackground = false;
  
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
    _loadRejectionReasons();
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
      _isAppInBackground = false;
      _startAutoRefresh();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isAppInBackground) {
          _refreshOrderStatus();
        }
      });
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _isAppInBackground = true;
      _autoRefreshTimer?.cancel();
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
    } on SocketException catch (e) {
      if (_isAppInBackground) return;
      print('❌ Error actualizando estado de orden: $e');
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
      if (mounted) {
        setState(() {
          deliveryPhotos = photos;
          _commentController.text = comment;
        });
      }
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

  Future<void> _loadRejectionReasons() async {
    if (!mounted) return;
    
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
      if (mounted) {
        print('❌ Error al cargar razones de rechazo: $e');
      }
    }
  }

  Future<void> _getRoutePoints() async {
    // Determinar origen usando GPS y fallback al origen de ruta
    LatLng? origin;
    try {
      final currentLocation = await LocationService.getCurrentLocation();
      if (currentLocation != null) {
        origin = LatLng(currentLocation.latitude, currentLocation.longitude);
      }
    } catch (_) {}

    origin ??= (widget.routeStartLatitude != null &&
            widget.routeStartLongitude != null)
        ? LatLng(widget.routeStartLatitude!, widget.routeStartLongitude!)
        : null;

    if (mounted) {
      setState(() {
        _originLatLng = origin;
      });
    }

    // Validar que tengamos todas las coordenadas necesarias
    if (origin == null || widget.latitude == null || widget.longitude == null) {
      print('⚠️ Coordenadas incompletas, usando ruta simple');
      _useFallbackRoute();
      return;
    }
    
    try {
      final String url =
          'https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${widget.longitude},${widget.latitude}?overview=full&geometries=geojson';

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

            if (mounted) {
              setState(() {
                routePoints = decodedPoints;
                isLoadingRoute = false;
              });
            }

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
    if (!mounted) return;
    setState(() {
      // Crear una línea recta entre inicio y fin si hay coordenadas
      final fallbackOrigin = _originLatLng ??
          ((widget.routeStartLatitude != null &&
                  widget.routeStartLongitude != null)
              ? LatLng(widget.routeStartLatitude!, widget.routeStartLongitude!)
              : null);

      if (fallbackOrigin != null &&
          widget.latitude != null &&
          widget.longitude != null) {
        routePoints = [
          fallbackOrigin,
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

  LatLng? _resolveOriginLatLng() {
    if (_originLatLng != null) return _originLatLng;
    if (widget.routeStartLatitude != null &&
        widget.routeStartLongitude != null) {
      return LatLng(widget.routeStartLatitude!, widget.routeStartLongitude!);
    }
    return null;
  }

  Future<void> _removePhoto(int index) async {
    if (mounted) {
      setState(() {
        deliveryPhotos.removeAt(index);
      });
    }
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
          if (mounted) {
            setState(() {
              _removePhoto(index);
            });
          }
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

  Future<void> _openRouteInMaps() async {
    // Validar coordenadas de destino
    if (widget.latitude == null || widget.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se tienen las coordenadas de la orden'),
        ),
      );
      return;
    }

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Obteniendo tu ubicación actual...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Obtener ubicación actual del conductor
      final currentLocation = await LocationService.getCurrentLocation();
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading dialog

      if (currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener tu ubicación actual. Asegúrate de tener permisos y GPS activado.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print(
        '🗺️ Abriendo ruta desde ubicación actual (${currentLocation.latitude}, ${currentLocation.longitude}) hasta orden (${widget.latitude}, ${widget.longitude})',
      );

      // Abrir ruta desde ubicación actual hasta la orden
      final bool success = await MapsService.openRouteInMaps(
        originLat: currentLocation.latitude,
        originLng: currentLocation.longitude,
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
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    // Validar que haya razones de rechazo
    if (rejectionReasons.isEmpty) {
      print('⚠️ Sin razones de rechazo disponibles');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No hay razones de rechazo disponibles. Intenta más tarde.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print('🔴 Construyendo RejectOrderModal con ${rejectionReasons.length} razones');
        return RejectOrderModal(
          orderNumber: widget.orderNumber,
          clientName: widget.clientName,
          rejectionReasons: rejectionReasons,
        );
      },
    );

    print('🔴 Modal cerrado con resultado: $result');

    if (result != null && mounted) {
      // Aquí puedes procesar los datos del rechazo
      print('🔴 Orden rechazada:');
      print('   Motivo ID: ${result['reasonId']}');
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
          reasonId: result['reasonId'],
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
    final origin = _resolveOriginLatLng();
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
                        child: (origin == null ||
                          widget.latitude == null ||
                          widget.longitude == null)
                            ? Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Text(
                                    isLoadingRoute
                                        ? 'Cargando mapa...'
                                        : 'Coordenadas no disponibles',
                                    style: const TextStyle(color: Colors.grey),
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
                                    (origin.latitude + widget.latitude!) / 2,
                                    (origin.longitude + widget.longitude!) / 2,
                                  ),
                                  zoom: 14.0,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('route_start'),
                                    position: LatLng(origin.latitude, origin.longitude),
                                    infoWindow: InfoWindow(
                                      title: _originLatLng != null
                                          ? 'Mi ubicación'
                                          : 'Inicio',
                                    ),
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
                                            LatLng(origin.latitude, origin.longitude),
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
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'Elige solo una opción',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
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
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
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
