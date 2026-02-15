import 'package:flutter/material.dart';

enum RouteStatus {
  toValidate,
  inRoute,
  finished,
}

extension RouteStatusExt on RouteStatus {
  String get label {
    return {
      RouteStatus.toValidate: 'Por validar',
      RouteStatus.inRoute: 'En ruta',
      RouteStatus.finished: 'Terminado',
    }[this]!;
  }

  Color get color {
    return {
      RouteStatus.toValidate: const Color(0xFFF59E0B),
      RouteStatus.inRoute: const Color(0xFF3B82F6),
      RouteStatus.finished: const Color(0xFF10B981),
    }[this]!;
  }

  int get colorInt {
    return {
      RouteStatus.toValidate: 0xFFF59E0B,
      RouteStatus.inRoute: 0xFF3B82F6,
      RouteStatus.finished: 0xFF10B981,
    }[this]!;
  }
}
