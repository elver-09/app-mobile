import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Estado persistido del correlativo visual de una ruta.
///
/// El correlativo pertenece a la combinación routeId + orderId y NO depende
/// del token ni del estado actual de la orden. Por eso una orden que desaparece
/// de la lista (reprogramada, entregada, rechazada, etc.) conserva su número y
/// ese número no se reutiliza para una orden nueva.
class RouteOrderSequenceState {
  final Map<int, int> sequenceByOrderId;
  final int nextSequence;

  const RouteOrderSequenceState({
    required this.sequenceByOrderId,
    required this.nextSequence,
  });
}

class RouteOrderSequenceStore {
  static const String _keyPrefix = 'trainyl_route_order_sequence_v1_';

  // Serializa las escrituras por ruta para evitar que dos refresh simultáneos
  // asignen el mismo correlativo a órdenes diferentes.
  static final Map<int, Future<void>> _routeTails = <int, Future<void>>{};

  static String _keyForRoute(int routeId) => '$_keyPrefix$routeId';

  static Future<T> _synchronized<T>(
    int routeId,
    Future<T> Function() action,
  ) async {
    final previous = _routeTails[routeId] ?? Future<void>.value();
    final completer = Completer<void>();
    final currentTail = completer.future;
    _routeTails[routeId] = currentTail;

    try {
      try {
        await previous;
      } catch (_) {
        // Una operación anterior fallida no debe bloquear futuras lecturas.
      }
      return await action();
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      if (identical(_routeTails[routeId], currentTail)) {
        _routeTails.remove(routeId);
      }
    }
  }

  /// Asigna correlativos únicamente a las órdenes nuevas y persiste el mapa.
  /// Las órdenes conocidas mantienen siempre el mismo número.
  static Future<RouteOrderSequenceState> assignForOrders({
    required int routeId,
    required Iterable<int> orderIds,
  }) {
    return _synchronized(routeId, () async {
      final prefs = await SharedPreferences.getInstance();
      final state = _decodeState(prefs.getString(_keyForRoute(routeId)));

      final sequenceByOrderId = Map<int, int>.from(state.sequenceByOrderId);
      var nextSequence = state.nextSequence;
      var changed = false;

      for (final orderId in orderIds) {
        if (sequenceByOrderId.containsKey(orderId)) {
          continue;
        }

        sequenceByOrderId[orderId] = nextSequence;
        nextSequence += 1;
        changed = true;
      }

      final updatedState = RouteOrderSequenceState(
        sequenceByOrderId: sequenceByOrderId,
        nextSequence: nextSequence,
      );

      if (changed || prefs.getString(_keyForRoute(routeId)) == null) {
        await prefs.setString(
          _keyForRoute(routeId),
          _encodeState(updatedState),
        );
      }

      return updatedState;
    });
  }

  /// Elimina el correlativo de una ruta que ya fue cerrada definitivamente.
  static Future<void> clearRoute(int routeId) {
    return _synchronized(routeId, () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyForRoute(routeId));
    });
  }

  static RouteOrderSequenceState _decodeState(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const RouteOrderSequenceState(
        sequenceByOrderId: <int, int>{},
        nextSequence: 1,
      );
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Formato inválido');
      }

      final sequenceByOrderId = <int, int>{};
      final rawOrders = decoded['orders'];
      if (rawOrders is Map) {
        rawOrders.forEach((key, value) {
          final orderId = int.tryParse(key.toString());
          final sequence = value is int
              ? value
              : int.tryParse(value.toString());
          if (orderId != null && sequence != null && sequence > 0) {
            sequenceByOrderId[orderId] = sequence;
          }
        });
      }

      var nextSequence = decoded['next'] is int
          ? decoded['next'] as int
          : int.tryParse(decoded['next']?.toString() ?? '') ?? 1;

      if (sequenceByOrderId.isNotEmpty) {
        final maxAssigned = sequenceByOrderId.values.reduce(
          (a, b) => a > b ? a : b,
        );
        if (nextSequence <= maxAssigned) {
          nextSequence = maxAssigned + 1;
        }
      }
      if (nextSequence < 1) {
        nextSequence = 1;
      }

      return RouteOrderSequenceState(
        sequenceByOrderId: sequenceByOrderId,
        nextSequence: nextSequence,
      );
    } catch (_) {
      // Si alguna versión anterior dejó datos corruptos, se recupera de forma
      // segura comenzando una nueva tabla para esa ruta.
      return const RouteOrderSequenceState(
        sequenceByOrderId: <int, int>{},
        nextSequence: 1,
      );
    }
  }

  static String _encodeState(RouteOrderSequenceState state) {
    final orders = <String, int>{};
    state.sequenceByOrderId.forEach((orderId, sequence) {
      orders[orderId.toString()] = sequence;
    });

    return jsonEncode(<String, dynamic>{
      'next': state.nextSequence,
      'orders': orders,
    });
  }
}
