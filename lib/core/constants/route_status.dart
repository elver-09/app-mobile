import 'package:flutter/material.dart';

enum RouteStatus {
  pending,
  completed,
}

extension RouteStatusExt on RouteStatus {
  String get label {
    return {
      RouteStatus.pending: 'Pendiente',
      RouteStatus.completed: 'Terminado',
    }[this]!;
  }

  Color get color {
    return {
      RouteStatus.pending: const Color(0xFF9CA3AF),
      RouteStatus.completed: const Color(0xFF059669),
    }[this]!;
  }

  int get colorInt {
    return {
      RouteStatus.pending: 0xFF9CA3AF,
      RouteStatus.completed: 0xFF059669,
    }[this]!;
  }
}
