import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/presentation/widgets/route_orders/order_sequence_warning_dialog.dart';

/// Botón para iniciar manualmente cualquier orden de la ruta
class StartOrderButton extends StatefulWidget {
  final int orderId;
  final int routeId;
  final String orderNumber;
  final String token;
  final OdooClient odooClient;
  final VoidCallback? onSuccess;
  
  /// Lista de todas las órdenes para detectar la siguiente planeada
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

  /// Obtiene la próxima orden pendiente que debería iniciarse según planificación
  OrderItem? _getNextPlannedOrder() {
    for (final order in widget.allOrders) {
      if (order.planningStatus == 'pending' && order.id != widget.orderId) {
        return order;
      }
    }
    return null;
  }

  Future<void> _startSpecificOrder() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Llamar al endpoint para iniciar esta orden específica
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

  void _showConfirmDialog() {
    // Obtener la orden actual (la seleccionada)
    OrderItem? currentOrder;
    for (final order in widget.allOrders) {
      if (order.id == widget.orderId) {
        currentOrder = order;
        break;
      }
    }

    if (currentOrder == null) return;

    // Obtener la próxima orden planeada
    final plannedOrder = _getNextPlannedOrder();

    // Si no hay orden planeada diferente, iniciar directamente
    if (plannedOrder == null || plannedOrder.id == widget.orderId) {
      _startSpecificOrder();
      return;
    }

    // Mostrar diálogo de advertencia si la orden seleccionada no es la planeada
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return OrderSequenceWarningDialog(
          selectedOrder: currentOrder!,
          plannedOrder: plannedOrder,
          onConfirmSelected: _startSpecificOrder,
          onConfirmPlanned: () async {
            // Iniciar la orden planeada en su lugar
            setState(() {
              _isLoading = true;
            });

            // Guardar context antes de await
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            try {
              final result = await widget.odooClient.startSpecificOrder(
                token: widget.token,
                orderId: plannedOrder.id,
                routeId: widget.routeId,
              );

              if (!mounted) return;

              if (result['success'] == true) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('✅ Orden ${plannedOrder.orderNumber} iniciada'),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 2),
                  ),
                );
                widget.onSuccess?.call();
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('❌ ${result["error"] ?? "Error al iniciar orden"}'),
                    backgroundColor: const Color(0xFFEF4444),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(
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
          },
          onCancel: () {
            // No hacer nada, solo cerrar
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _showConfirmDialog,
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
        side: const BorderSide(
          color: Color(0xFF3B82F6),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
