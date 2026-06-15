import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';

/// Botón para iniciar manualmente cualquier orden de la ruta.
/// Inicia directamente; el backend bloquea si ya hay otra orden en curso.
class StartOrderButton extends StatefulWidget {
  final int orderId;
  final int routeId;
  final String orderNumber;
  final String token;
  final OdooClient odooClient;
  final VoidCallback? onSuccess;

  /// Lista de todas las órdenes (se mantiene por compatibilidad con la pantalla).
  final List<OrderItem> allOrders;

  const StartOrderButton({
    super.key,
    required this.orderId,
    required this.routeId,
    required this.orderNumber,
    required this.token,
    required this.odooClient,
    this.onSuccess,
    required this.allOrders,
  });

  @override
  State<StartOrderButton> createState() => _StartOrderButtonState();
}

class _StartOrderButtonState extends State<StartOrderButton> {
  bool _isLoading = false;

  Future<void> _startSpecificOrder() async {
    if (!mounted || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.odooClient.startSpecificOrder(
        token: widget.token,
        orderId: widget.orderId,
        routeId: widget.routeId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Orden ${widget.orderNumber} iniciada'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onSuccess?.call();
      } else {
        // Incluye el caso "Ya tienes una orden en curso" que valida el backend.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result["error"] ?? "Error al iniciar orden"}'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _startSpecificOrder,
      icon: _isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF3B82F6),
              ),
            )
          : const Icon(
              Icons.play_circle_outline,
              size: 18,
              color: Color(0xFF3B82F6),
            ),
      label: Text(
        _isLoading ? 'Iniciando...' : 'Iniciar',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3B82F6),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
