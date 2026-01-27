import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:trainyl_2_0/core/odoo/route_model.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';

/// Clase para la respuesta de órdenes de ruta con información del vehículo
class RouteOrdersResponse {
  final List<OrderItem> orders;
  final String fleetType;
  final String fleetLicense;
  final double? routeStartLatitude;
  final double? routeStartLongitude;

  RouteOrdersResponse({
    required this.orders,
    required this.fleetType,
    required this.fleetLicense,
    this.routeStartLatitude,
    this.routeStartLongitude,
  });
}

class DriverInfo {
  final int employeeId;
  final String name;
  final String email;
  final String phone;
  final String job;
  final int routeId;
  final String? routeName;

  DriverInfo({
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.job,
    required this.routeId,
    this.routeName,
  });
}

class OdooAuthResult {
  final DriverInfo driver;
  final String token;

  OdooAuthResult({
    required this.driver,
    required this.token,
  });
}

class OdooClient {
  final String baseUrl;
  final String db;

  const OdooClient({required this.baseUrl, required this.db});

  Future<OdooAuthResult?> login({
    required String login,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/driver/login');

    final resp = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'login': login,
          'password': password,
        },
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final result = data['result'];

    if (result == null || result['success'] != true) {
      // Credenciales inválidas o error del servidor
      return null;
    }

    final driverData = result['driver'];
    if (driverData == null) {
      throw Exception('Datos de conductor faltantes en la respuesta');
    }

    final token = result['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Token no recibido del servidor');
    }

    final driver = DriverInfo(
      employeeId: driverData['employee_id'] as int,
      name: driverData['name'] as String,
      email: driverData['email'] as String? ?? '',
      phone: driverData['phone'] as String? ?? '',
      job: driverData['job'] as String? ?? '',
      routeId: 0,
      routeName: null,
    );

    return OdooAuthResult(
      driver: driver,
      token: token,
    );
  }

  /// Obtiene las rutas del día del conductor autenticado
  Future<List<RouteItem>> fetchTodayRoutes(String token) async {
    final url = Uri.parse('$baseUrl/driver/routes/today');

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {},
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final result = data['result'];

    if (result == null || result['success'] != true) {
      return [];
    }

    final List routesData = result['routes'] ?? [];
    return routesData
        .map((r) => RouteItem.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene las órdenes de una ruta específica
  Future<RouteOrdersResponse> fetchRouteOrders({
    required String token,
    required int routeId,
  }) async {
    final url = Uri.parse('$baseUrl/driver/routes/orders');

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'route_id': routeId,
        },
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final result = data['result'];
    if (result == null || result['success'] != true) {
      return RouteOrdersResponse(
        orders: [],
        fleetType: 'Vehículo',
        fleetLicense: 'N/A',
      );
    }

    final List ordersData = result['orders'] ?? [];
    final orders = ordersData
        .map((o) => OrderItem.fromJson(o as Map<String, dynamic>))
        .toList();
    
    return RouteOrdersResponse(
      orders: orders,
      fleetType: result['fleet_type'] as String? ?? 'Vehículo',
      fleetLicense: result['fleet_license'] as String? ?? 'N/A',
      routeStartLatitude: result['route_start_latitude'] as double?,
      routeStartLongitude: result['route_start_longitude'] as double?,
    );
  }

  /// Obtiene el detalle completo de una orden específica
  Future<OrderItem?> fetchOrderDetail({
    required String token,
    required int orderId,
  }) async {
    final url = Uri.parse('$baseUrl/driver/order/detail');

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'order_id': orderId,
        },
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    print('📦 Respuesta del servidor: $data');
    
    final result = data['result'];
    if (result == null || result['success'] != true) {
      print('❌ Success = false. Error: ${result?['error']}');
      return null;
    }

    final orderData = result['order'];
    if (orderData == null) {
      print('❌ orderData es null');
      return null;
    }

    print('✅ Orden recibida: $orderData');
    return OrderItem.fromJson(orderData as Map<String, dynamic>);
  }
}

