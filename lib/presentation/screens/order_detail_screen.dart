import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

// Core services
import '../../core/services/photo_storage_service.dart';

// Widgets
import '../widgets/order_detail/order_info_card.dart';
import '../widgets/order_detail/delivery_photos_widget.dart';
import '../widgets/order_detail/photo_view_dialog.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String clientName;
  final String phone;
  final String address;
  final String product;
  final String district;
  final String reference;
  final String token;
  final double latitude;
  final double longitude;
  final String googleMapsUrl;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.clientName,
    required this.phone,
    required this.address,
    required this.product,
    required this.district,
    required this.reference,
    required this.token,
    this.latitude = -8.00295,
    this.longitude = -78.3163062,
    this.googleMapsUrl = 'https://www.google.com/maps/@-8.00295,-78.3163062,12074m/data=!3m1!1e3?authuser=0&entry=ttu&g_ep=EgoyMDI2MDEwNy4wIKXMDSoASAFQAw%3D%3D',
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late GoogleMapController mapController;
  GoogleMapController? routeMapController;
  
  // Coordenadas de inicio de ruta
  final double routeStartLat = -8.000056;
  final double routeStartLng = -78.3067795;
  
  // ⚠️ REEMPLAZA ESTO CON TU API KEY DE GOOGLE CLOUD
  // 1. Ve a https://console.cloud.google.com
  // 2. Crea un proyecto o selecciona uno existente
  // 3. Habilita "Maps SDK for Android" y "Directions API"
  // 4. Crea una API key
  // 5. Reemplaza la key abajo
  final String GOOGLE_MAPS_API_KEY = 'AIzaSyCxTlk0WgcQzu_Odxmk2ROu6peiUOX-8Wk';
  
  List<LatLng> routePoints = [];
  bool isLoadingRoute = true;
  List<File> deliveryPhotos = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print('📍 OrderDetailScreen - Lat: ${widget.latitude}, Lng: ${widget.longitude}');
    _getRoutePoints();
    _loadSavedPhotos();
  }

  Future<void> _loadSavedPhotos() async {
    try {
      final photos = await PhotoStorageService.loadPhotos(widget.orderId.toString());
      setState(() {
        deliveryPhotos = photos;
      });
      print('📸 Fotos cargadas para orden ${widget.orderId}: ${deliveryPhotos.length}');
    } catch (e) {
      print('❌ Error al cargar fotos: $e');
    }
  }

  Future<void> _savePhotos() async {
    try {
      await PhotoStorageService.savePhotoPaths(widget.orderId.toString(), deliveryPhotos);
      print('💾 Fotos guardadas para orden ${widget.orderId}: ${deliveryPhotos.length}');
    } catch (e) {
      print('❌ Error al guardar fotos: $e');
    }
  }

  Future<void> _getRoutePoints() async {
    try {
      final String url =
          'https://router.project-osrm.org/route/v1/driving/$routeStartLng,$routeStartLat;${widget.longitude},${widget.latitude}?overview=full&geometries=geojson';

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
      isLoadingRoute = false;
      routePoints = [
        LatLng(routeStartLat, routeStartLng),
        LatLng(widget.latitude, widget.longitude),
      ];
    });
  }

  Future<void> _takePhoto() async {
    if (deliveryPhotos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 2 fotos permitidas')),
      );
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          deliveryPhotos.add(File(photo.path));
        });
        await _savePhotos();
        print('📷 Foto capturada: ${photo.path}');
      }
    } catch (e) {
      print('❌ Error al capturar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar foto: $e')),
      );
    }
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
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      print('✅ Llamada iniciada correctamente');
    } catch (e) {
      print('❌ Error al iniciar la llamada: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print('📍 Mapa creado - Lat: ${widget.latitude}, Lng: ${widget.longitude}');
  }

  void _onRouteMapCreated(GoogleMapController controller) {
    routeMapController = controller;
    print('🛣️ Mapa de ruta creado');
  }

  Widget _buildStatusButton(
    String label,
    IconData icon,
    Color backgroundColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                        const Text(
                          'Hoy · Ruta 12 · En curso',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Vehículo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Moto · ABC-123',
                                style: TextStyle(
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
                      reference: widget.reference,
                      district: widget.district,
                      onCallPressed: () => _makePhoneCall(widget.phone),
                      onMapPressed: () {
                        // TODO: Implementar apertura de mapa externo
                      },
                    ),
                    const SizedBox(height: 24),
                    // Location section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ubicación de entrega',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Vista previa de la ruta',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Map preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 220,
                                child: GoogleMap(
                                  onMapCreated: _onMapCreated,
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(widget.latitude, widget.longitude),
                                    zoom: 17.0,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('delivery_location'),
                                      position: LatLng(widget.latitude, widget.longitude),
                                      infoWindow: InfoWindow(
                                        title: widget.clientName,
                                        snippet: widget.address,
                                      ),
                                    ),
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 220,
                                child: GoogleMap(
                                  onMapCreated: _onRouteMapCreated,
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      (routeStartLat + widget.latitude) / 2,
                                      (routeStartLng + widget.longitude) / 2,
                                    ),
                                    zoom: 14.0,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('route_start'),
                                      position: LatLng(routeStartLat, routeStartLng),
                                      infoWindow: const InfoWindow(
                                        title: 'Inicio',
                                      ),
                                      icon: BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueGreen,
                                      ),
                                    ),
                                    Marker(
                                      markerId: const MarkerId('route_end'),
                                      position: LatLng(widget.latitude, widget.longitude),
                                      infoWindow: const InfoWindow(
                                        title: 'Destino',
                                      ),
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
                                              LatLng(routeStartLat, routeStartLng),
                                              LatLng(widget.latitude, widget.longitude),
                                            ]
                                          : routePoints,
                                    ),
                                  },
                                  zoomGesturesEnabled: false,
                                  scrollGesturesEnabled: false,
                                  rotateGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                  mapToolbarEnabled: false,
                                ),
                              ),
                            ),
                          ],
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
                    _buildStatusButton(
                      'Marcar como entregado',
                      Icons.check_circle_outline,
                      const Color(0xFF10B981),
                      () {},
                    ),
                    const SizedBox(height: 12),
                    _buildStatusButton(
                      'Marcar como rechazado',
                      Icons.cancel_outlined,
                      const Color(0xFFEF4444),
                      () {},
                    ),
                    const SizedBox(height: 12),
                    _buildStatusButton(
                      'No disponible en domicilio',
                      Icons.error_outline,
                      const Color(0xFFF97316),
                      () {},
                    ),
                    const SizedBox(height: 24),
                    // Widget de fotos
                    DeliveryPhotosWidget(
                      photos: deliveryPhotos,
                      maxPhotos: 2,
                      onTakePhoto: _takePhoto,
                      onViewPhotos: _showPhotosDialog,
                      onRemovePhoto: _removePhoto,
                    ),
                    const SizedBox(height: 16),
                    // Comment field
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Comentario para la central y el cliente\n(opcional)',
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
                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text('Confirmar estado y continuar ruta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Al confirmar, la orden se actualiza en tiempo real y se cargará la siguiente parada optimizada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
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