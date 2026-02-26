import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:trainyl_2_0/core/odoo/route_model.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';

/// Clase para la respuesta de órdenes de ruta con información del vehículo
class RouteOrdersResponse {
  final List<OrderItem> orders;
  final String fleetType;
  final String fleetLicense;
  final String? routeStartAddress;
  final double? routeStartLatitude;
  final double? routeStartLongitude;
  final String? routeStatus;

  RouteOrdersResponse({
    required this.orders,
    required this.fleetType,
    required this.fleetLicense,
    this.routeStartAddress,
    this.routeStartLatitude,
    this.routeStartLongitude,
    this.routeStatus,
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

  OdooClient({required String baseUrl, required this.db})
      : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

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
    final url = Uri.parse('$baseUrl/driver/routes/orders/$routeId');

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
      routeStartAddress: result['route_start_address'] as String?,
      routeStartLatitude: result['route_start_latitude'] as double?,
      routeStartLongitude: result['route_start_longitude'] as double?,
      routeStatus: result['route_status'] as String?,
    );
  }

  /// Obtiene el detalle completo de una orden específica
  Future<OrderItem?> fetchOrderDetail({
    required String token,
    required int orderId,
  }) async {
    final url = Uri.parse('$baseUrl/driver/order/detail/$orderId');

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

  /// Actualizar estado de orden a ENTREGADA
  Future<bool> updateOrderDelivered({
    required String token,
    required int orderId,
    required String recipientName,
    required List<String> photoBase64List,
  }) async {
    final url = Uri.parse('$baseUrl/driver/order/update_delivered');
    
    try {
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
            'recipient_name': recipientName,
            'delivery_photos': photoBase64List,
            'delivery_date': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (resp.statusCode != 200) {
        print('❌ Error HTTP en updateOrderDelivered: ${resp.statusCode}');
        print('   Body: ${resp.body}');
        return false;
      }

      final data = jsonDecode(resp.body);
      print('📦 Respuesta Odoo updateOrderDelivered: $data');
      final result = data['result'];
      
      if (result != null && result['success'] == true) {
        print('✅ Orden entregada sincronizada con Odoo');
        return true;
      } else {
        print('❌ Error al sincronizar');
        print('   result: $result');
        print('   error: ${result?['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Exception en updateOrderDelivered: $e');
      return false;
    }
  }

  /// Envía una reprogramación de orden al backend
  Future<bool> reprogramOrder({
    required String token,
    required int orderId,
    required String deliveryDateIso,
    String? comment,
  }) async {
    final url = Uri.parse('$baseUrl/driver/order/reprogram');

    try {
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
            'delivery_date': deliveryDateIso,
            'comment': comment ?? '',
          },
        }),
      );

      if (resp.statusCode != 200) {
        print('❌ Error HTTP en reprogramOrder: ${resp.statusCode}');
        print('   Body: ${resp.body}');
        return false;
      }

      final data = jsonDecode(resp.body);
      print('📦 Respuesta Odoo reprogramOrder: $data');
      final result = data['result'];

      if (result != null && result['success'] == true) {
        print('✅ Reprogramación sincronizada con Odoo');
        return true;
      } else {
        print('❌ Error al sincronizar reprogramación');
        print('   result: $result');
        print('   error: ${result?['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Exception en reprogramOrder: $e');
      return false;
    }
  }

  /// Actualizar estado de orden a RECHAZADA
  Future<bool> updateOrderRejected({
    required String token,
    required int orderId,
    required String reason,
    int? reasonId,
    required String comment,
    required List<String> photoBase64List,
  }) async {
    final url = Uri.parse('$baseUrl/driver/order/update_rejected');
    
    try {
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
            'reject_reason': reason,
            'reject_reason_id': reasonId,
            'reject_comment': comment,
            'reject_photos': photoBase64List,
            'rejection_date': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (resp.statusCode != 200) {
        print('❌ Error HTTP en updateOrderRejected: ${resp.statusCode}');
        print('   Body: ${resp.body}');
        return false;
      }

      final data = jsonDecode(resp.body);
      print('📦 Respuesta Odoo updateOrderRejected: $data');
      final result = data['result'];
      
      if (result != null && result['success'] == true) {
        print('✅ Orden rechazada sincronizada con Odoo');
        return true;
      } else {
        print('❌ Error al sincronizar');
        print('   result: $result');
        print('   error: ${result?['error']}');
        return false;
      }
    } catch (e) {
      print('❌ Exception en updateOrderRejected: $e');
      return false;
    }
  }

  /// Iniciar la siguiente orden de la ruta (optimizada por cercanía)
  Future<Map<String, dynamic>> startNextOrder({
    required String token,
    required int routeId,
  }) async {
    final url = Uri.parse('$baseUrl/driver/order/start_next/$routeId');
    
    try {
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
        print('❌ Error HTTP en startNextOrder: ${resp.statusCode}');
        return {'success': false, 'error': 'HTTP ${resp.statusCode}'};
      }

      final data = jsonDecode(resp.body);
      print('📦 Respuesta Odoo startNextOrder: $data');
      final result = data['result'];
      
      if (result != null && result['success'] == true) {
        print('✅ Siguiente orden iniciada correctamente');
        return result;
      } else {
        print('❌ Error al iniciar siguiente orden');
        return result ?? {'success': false, 'error': 'Sin respuesta'};
      }
    } catch (e) {
      print('❌ Exception en startNextOrder: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Iniciar una orden específica manualmente
  Future<Map<String, dynamic>> startSpecificOrder({
    required String token,
    required int orderId,
    required int routeId,
  }) async {
    final url = Uri.parse('$baseUrl/driver/order/start/$routeId/$orderId');
    
    try {
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
        print('❌ Error HTTP en startSpecificOrder: ${resp.statusCode}');
        return {'success': false, 'error': 'HTTP ${resp.statusCode}'};
      }

      final data = jsonDecode(resp.body);
      print('📦 Respuesta Odoo startSpecificOrder: $data');
      final result = data['result'];
      
      if (result != null && result['success'] == true) {
        print('✅ Orden específica iniciada correctamente');
        return result;
      } else {
        print('❌ Error al iniciar orden específica');
        return result ?? {'success': false, 'error': 'Sin respuesta'};
      }
    } catch (e) {
      print('❌ Exception en startSpecificOrder: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Iniciar siguiente orden desde ubicación actual
  Future<Map<String, dynamic>> startNextOrderFromCurrent({
    required String token,
    required int currentOrderId,
    required int routeId,
  }) async {
    final url = Uri.parse('$baseUrl/driver/order/start_next_from_current/$routeId/$currentOrderId');
    
    try {
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
        print('❌ Error HTTP en startNextOrderFromCurrent: ${resp.statusCode}');
        return {'success': false, 'error': 'HTTP ${resp.statusCode}'};
      }

      final data = jsonDecode(resp.body);
      print('📦 Respuesta Odoo startNextOrderFromCurrent: $data');
      final result = data['result'];
      
      if (result != null && result['success'] == true) {
        print('✅ Siguiente orden iniciada desde ubicación actual');
        return result as Map<String, dynamic>;
      } else {
        print('❌ Error al iniciar siguiente orden desde ubicación actual');
        return result ?? {'success': false, 'error': 'Sin respuesta'};
      }
    } catch (e) {
      print('❌ Exception en startNextOrderFromCurrent: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Obtiene las razones de rechazo disponibles en móvil
  Future<List<Map<String, dynamic>>> fetchRejectionReasons({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/driver/rejection/reasons');

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
      print('❌ HTTP Error en fetchRejectionReasons: ${resp.statusCode}');
      return [];
    }

    final data = jsonDecode(resp.body);
    print('📦 Respuesta razones de rechazo: $data');
    
    final result = data['result'];
    if (result == null || result['success'] != true) {
      print('❌ Error obteniendo razones de rechazo');
      return [];
    }

    final List reasonsData = result['reasons'] ?? [];
    print('✅ Razones obtenidas: ${reasonsData.length}');
    return reasonsData.cast<Map<String, dynamic>>();
  }

  /// Confirmar escaneo de orden (cambiar de in_planification a in_transport)
  Future<Map<String, dynamic>> scanConfirmOrder({
    required String token,
    required int orderId,
  }) async {
    print('🟢 ===== ODOO CLIENT: scanConfirmOrder =====');
    print('🟢 Order ID: $orderId');
    print('🟢 Token length: ${token.length}');
    
    final url = Uri.parse('$baseUrl/driver/order/scan_confirm/$orderId');
    print('🟢 URL: $url');
    
    try {
      print('🟢 Enviando petición POST...');
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

      print('🟢 Respuesta HTTP recibida');
      print('🟢 Status Code: ${resp.statusCode}');
      print('🟢 Body: ${resp.body}');

      if (resp.statusCode != 200) {
        print('❌ Error HTTP en scanConfirmOrder: ${resp.statusCode}');
        return {'success': false, 'error': 'HTTP ${resp.statusCode}'};
      }

      final data = jsonDecode(resp.body);
      print('🟢 JSON decodificado:');
      print('🟢 Data completo: $data');
      
      final result = data['result'];
      print('🟢 Result extraído: $result');
      
      if (result != null && result['success'] == true) {
        print('✅ ÉXITO en OdooClient: Orden confirmada');
        print('✅ Nuevo estado reportado por Odoo: ${result['new_status']}');
        print('✅ Mensaje: ${result['message']}');
        return result;
      } else {
        print('❌ Error en resultado de Odoo');
        print('❌ Success: ${result?['success']}');
        print('❌ Error: ${result?['error']}');
        return result ?? {'success': false, 'error': 'Sin respuesta'};
      }
    } catch (e) {
      print('❌ EXCEPCIÓN en scanConfirmOrder: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return {'success': false, 'error': e.toString()};
    } finally {
      print('🟢 ===== FIN ODOO CLIENT: scanConfirmOrder =====');
    }
  }

  Future<Map<String, dynamic>> searchOrderGlobal({
    required String token,
    required String orderCode,
  }) async {
    print('🟢 ===== ODOO CLIENT: searchOrderGlobal =====');
    print('🟢 Order Code: $orderCode');
    print('🟢 Token length: ${token.length}');
    
    final url = Uri.parse('$baseUrl/driver/order/search_global').replace(
      queryParameters: {'order_code': orderCode},
    );
    print('🟢 URL: $url');
    
    try {
      print('🟢 Enviando petición GET...');
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🟢 Respuesta HTTP recibida');
      print('🟢 Status Code: ${resp.statusCode}');
      print('🟢 Body: ${resp.body}');

      if (resp.statusCode != 200) {
        print('❌ Error HTTP en searchOrderGlobal: ${resp.statusCode}');
        return {'success': false, 'error': 'HTTP ${resp.statusCode}'};
      }

      final data = jsonDecode(resp.body);
      print('🟢 JSON decodificado: $data');
      
      if (data['success'] == true) {
        print('✅ ÉXITO en OdooClient: Orden encontrada');
        return data;
      } else {
        print('❌ Error en búsqueda: ${data['error']}');
        return data;
      }
    } catch (e) {
      print('❌ EXCEPCIÓN en searchOrderGlobal: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return {'success': false, 'error': e.toString()};
    } finally {
      print('🟢 ===== FIN ODOO CLIENT: searchOrderGlobal =====');
    }
  }
}

