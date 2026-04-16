import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trainyl_2_0/core/services/location_service.dart';
import 'package:trainyl_2_0/core/services/maps_service.dart';

class GroupedOrderCard extends StatefulWidget {
  final GroupedOrder groupedOrder;
  final VoidCallback onTap;
  final bool showManageButton;
  final bool showReprogramButton;
  final VoidCallback? onReprogramTap;

  const GroupedOrderCard({
    super.key,
    required this.groupedOrder,
    required this.onTap,
    this.showManageButton = true,
    this.showReprogramButton = false,
    this.onReprogramTap,
  });

  @override
  State<GroupedOrderCard> createState() => _GroupedOrderCardState();
}

class _GroupedOrderCardState extends State<GroupedOrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final groupedOrder = widget.groupedOrder;
    final hasPhone =
        groupedOrder.orders.first.phone != null &&
        groupedOrder.orders.first.phone!.isNotEmpty;
    final orderWithCoordinates =
        groupedOrder.orders.where((o) {
          return o.latitude != null && o.longitude != null;
        }).isNotEmpty
        ? groupedOrder.orders.firstWhere(
            (o) => o.latitude != null && o.longitude != null,
          )
        : null;
    final hasMapButton =
        groupedOrder.address.trim().isNotEmpty ||
        orderWithCoordinates != null ||
        (groupedOrder.latitude != null && groupedOrder.longitude != null);

    // Verificar si todas las órdenes están en curso
    final allInCourse = groupedOrder.orders.every(
      (o) => o.planningStatus == 'start_of_route',
    );
    final allBlocked = groupedOrder.orders.every(
      (o) => o.planningStatus == 'blocked',
    );
    final multipackOrdersCount = groupedOrder.orders
        .where((o) => o.isMultipack && o.expectedPackages > 1)
        .length;
    final multipackRemainingPackages = groupedOrder.orders
        .where((o) => o.isMultipack && o.expectedPackages > 1)
        .fold<int>(0, (acc, o) => acc + o.remainingPackages);

    return Opacity(
      opacity: allBlocked ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: allInCourse
                ? [
                    const Color(0xFFFEF3C7), // Amarillo suave
                    const Color(0xFFFDE68A), // Amarillo más intenso
                  ]
                : [Colors.white, const Color(0xFFF5F9FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: allInCourse
                ? const Color(0xFFF59E0B) // Borde amarillo si está en curso
                : const Color(0xFF93C5FD),
            width: allInCourse ? 2.2 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.14),
              blurRadius: 14,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header del grupo
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.05),
                        const Color(0xFF3B82F6).withOpacity(0.02),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  padding: EdgeInsets.all(responsive.getResponsiveSize(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icono de grupo
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: responsive.getResponsiveSize(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  groupedOrder.clientName,
                                  style: TextStyle(
                                    fontSize: responsive.bodyMediumFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        groupedOrder.address,
                                        style: TextStyle(
                                          fontSize:
                                              responsive.bodySmallFontSize,
                                          color: const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: responsive.getResponsiveSize(8)),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF3B82F6),
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Indicadores de estado
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildStatusBadge(
                            label: '${groupedOrder.totalOrders} órdenes',
                            icon: Icons.shopping_bag,
                            color: const Color(0xFF3B82F6),
                            responsive: responsive,
                          ),
                          if (groupedOrder.deliveredCount > 0)
                            _buildStatusBadge(
                              label:
                                  '${groupedOrder.deliveredCount} entregadas',
                              icon: Icons.check_circle,
                              color: const Color(0xFF10B981),
                              responsive: responsive,
                            ),
                          if (groupedOrder.rejectedCount > 0)
                            _buildStatusBadge(
                              label: '${groupedOrder.rejectedCount} rechazadas',
                              icon: Icons.cancel,
                              color: const Color(0xFFEF4444),
                              responsive: responsive,
                            ),
                          if (groupedOrder.pendingCount > 0)
                            _buildStatusBadge(
                              label: '${groupedOrder.pendingCount} pendientes',
                              icon: Icons.schedule,
                              color: const Color(0xFFF59E0B),
                              responsive: responsive,
                            ),
                          if (multipackOrdersCount > 0)
                            _buildStatusBadge(
                              label: '$multipackOrdersCount multibulto',
                              icon: Icons.inventory_2,
                              color: const Color(0xFFEA580C),
                              responsive: responsive,
                            ),
                          if (multipackRemainingPackages > 0)
                            _buildStatusBadge(
                              label:
                                  '$multipackRemainingPackages bultos faltan',
                              icon: Icons.hourglass_top,
                              color: const Color(0xFFB45309),
                              responsive: responsive,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Órdenes expandidas
            if (_isExpanded) ...[
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                  ),
                ),
                padding: EdgeInsets.all(responsive.getResponsiveSize(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECCIÓN 1: Detalles del Cliente
                    _buildClientDetailsSection(groupedOrder, responsive),
                    SizedBox(height: responsive.getResponsiveSize(10)),
                    // SECCIÓN 2: Órdenes del Cliente
                    // Título de la sección
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.list_alt,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Órdenes del cliente (${groupedOrder.totalOrders})',
                          style: TextStyle(
                            fontSize: responsive.bodyMediumFontSize - 1,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.getResponsiveSize(6)),
                    // Lista de órdenes
                    ...groupedOrder.orders.map((order) {
                      return _buildOrderItem(order, responsive);
                    }),
                    SizedBox(height: responsive.getResponsiveSize(6)),
                    // Separador visual
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFE2E8F0),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.getResponsiveSize(6)),
                    // Botones de acciones
                    if (!allBlocked)
                      Row(
                        children: [
                          // Botón llamar (usa teléfono de la primera orden)
                          if (hasPhone)
                            Expanded(
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF10B981).withOpacity(0.1),
                                      const Color(0xFF10B981).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981),
                                    width: 1.5,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      _launchPhone(
                                        groupedOrder.orders.first.phone!,
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 18,
                                          color: const Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Llamar',
                                          style: TextStyle(
                                            fontSize:
                                                responsive.bodySmallFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (hasPhone &&
                              (hasMapButton ||
                                  widget.showManageButton ||
                                  widget.showReprogramButton))
                            SizedBox(width: responsive.getResponsiveSize(8)),
                          // Botón ver mapa (usa coordenadas disponibles o dirección)
                          if (hasMapButton)
                            Expanded(
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF3B82F6).withOpacity(0.1),
                                      const Color(0xFF3B82F6).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6),
                                    width: 1.5,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      _launchMap(
                                        lat:
                                            orderWithCoordinates?.latitude ??
                                            groupedOrder.latitude,
                                        lng:
                                            orderWithCoordinates?.longitude ??
                                            groupedOrder.longitude,
                                        address: groupedOrder.address,
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.map,
                                          size: 18,
                                          color: const Color(0xFF3B82F6),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Mapa',
                                          style: TextStyle(
                                            fontSize:
                                                responsive.bodySmallFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (hasMapButton &&
                              (widget.showManageButton ||
                                  widget.showReprogramButton))
                            SizedBox(width: responsive.getResponsiveSize(8)),
                          // Botón Gestionar
                          if (widget.showManageButton)
                            Expanded(
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF2563EB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: widget.onTap,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Gestionar',
                                          style: TextStyle(
                                            fontSize:
                                                responsive.bodySmallFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Botón Reprogramar
                          if (widget.showReprogramButton)
                            Expanded(
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF59E0B),
                                      Color(0xFFD97706),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: widget.onReprogramTap,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.event_repeat,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Reprogramar',
                                          style: TextStyle(
                                            fontSize:
                                                responsive.bodySmallFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientDetailsSection(
    GroupedOrder groupedOrder,
    ResponsiveHelper responsive,
  ) {
    final firstOrder = groupedOrder.orders.first;

    return Container(
      padding: EdgeInsets.all(responsive.getResponsiveSize(10)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teléfono
          if (firstOrder.phone != null && firstOrder.phone!.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.phone,
              label: 'Teléfono:',
              value: firstOrder.phone!,
              responsive: responsive,
              onTap: () => _launchPhone(firstOrder.phone!),
            ),
            SizedBox(height: responsive.getResponsiveSize(8)),
          ],
          // Dirección
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Dirección:',
            value: firstOrder.address,
            responsive: responsive,
            maxLines: 2,
          ),
          SizedBox(height: responsive.getResponsiveSize(8)),
          // Zona/Comas
          Text(
            firstOrder.district.isNotEmpty
                ? firstOrder.district.toUpperCase()
                : 'SIN ZONA',
            style: TextStyle(
              fontSize: responsive.bodySmallFontSize - 1,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ResponsiveHelper responsive,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    final widget = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        SizedBox(width: responsive.getResponsiveSize(10)),
        SizedBox(
          width: responsive.getResponsiveSize(70),
          child: Text(
            label,
            style: TextStyle(
              fontSize: responsive.bodySmallFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.bodySmallFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }
    return widget;
  }

  Widget _buildStatusBadge({
    required String label,
    required IconData icon,
    required Color color,
    required ResponsiveHelper responsive,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.getResponsiveSize(10),
        vertical: responsive.getResponsiveSize(6),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.bodySmallFontSize - 1,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem order, ResponsiveHelper responsive) {
    final showRibbon = order.planningStatus != 'in_transport';
    final isBlocked = order.planningStatus == 'blocked';

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Opacity(
          opacity: isBlocked ? 0.55 : 1.0,
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: responsive.getResponsiveSize(4),
            ),
            padding: EdgeInsets.all(responsive.getResponsiveSize(8)),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono decorativo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getOrderIcon(order.planningStatus),
                    color: order.statusColor,
                    size: 18,
                  ),
                ),
                SizedBox(width: responsive.getResponsiveSize(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if ((order.routeSequence ??
                                        order.sequence ??
                                        0) >
                                    0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0xFF93C5FD),
                                      ),
                                    ),
                                    child: Text(
                                      '# ${order.routeSequence ?? order.sequence}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    order.orderNumber,
                                    style: TextStyle(
                                      fontSize:
                                          responsive.bodySmallFontSize + 1,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!showRibbon)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.getResponsiveSize(10),
                                vertical: responsive.getResponsiveSize(4),
                              ),
                              decoration: BoxDecoration(
                                color: order.statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: order.statusColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                order.statusLabel,
                                style: TextStyle(
                                  fontSize: responsive.bodySmallFontSize - 2,
                                  fontWeight: FontWeight.w600,
                                  color: order.statusColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.product ?? 'Sin producto',
                              style: TextStyle(
                                fontSize: responsive.bodySmallFontSize - 1,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (order.isMultipack && order.expectedPackages > 1) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory,
                              size: 14,
                              color: const Color(0xFFEA580C),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Multibulto: ${order.scannedPackages}/${order.expectedPackages} · Faltan ${order.remainingPackages}',
                                style: TextStyle(
                                  fontSize: responsive.bodySmallFontSize - 2,
                                  color: const Color(0xFF9A3412),
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showRibbon)
          _buildOrderStatusRibbon(
            label: order.statusLabel,
            baseColor: order.statusColor,
          ),
      ],
    );
  }

  Widget _buildOrderStatusRibbon({
    required String label,
    required Color baseColor,
  }) {
    final ribbonColor = baseColor.withOpacity(0.95);
    final ribbonWidth = (label.length * 5.8).clamp(76.0, 104.0);

    return Positioned(
      top: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          width: ribbonWidth,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ribbonColor, ribbonColor.withOpacity(0.88)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(9),
              bottomLeft: Radius.circular(10),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getOrderIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'blocked':
        return Icons.lock_clock;
      case 'in_transport':
        return Icons.local_shipping;
      case 'start_of_route':
        return Icons.play_circle;
      default:
        return Icons.pending;
    }
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('❌ Error al iniciar la llamada: $e');
    }
  }

  void _launchMap({double? lat, double? lng, required String address}) async {
    final cleanAddress = address.trim();
    print('🗺️ Abriendo mapa para dirección: $cleanAddress ($lat, $lng)');

    try {
      // Si no hay coordenadas, abrir búsqueda por dirección
      if (lat == null || lng == null) {
        if (cleanAddress.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No hay dirección disponible para abrir en el mapa',
              ),
            ),
          );
          return;
        }

        final Uri googleMapsSearchUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cleanAddress)}',
        );

        final opened = await launchUrl(
          googleMapsSearchUri,
          mode: LaunchMode.externalApplication,
        );

        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir la aplicación de mapas'),
            ),
          );
        }
        return;
      }

      // Obtener ubicación actual del conductor
      final currentLocation = await LocationService.getCurrentLocation();

      if (currentLocation == null) {
        // Fallback: abrir solo el destino cuando no hay ubicación actual
        final bool opened = await MapsService.openLocationInMaps(
          latitude: lat,
          longitude: lng,
          label: cleanAddress,
        );

        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir la aplicación de mapas'),
            ),
          );
        }
        return;
      }

      print(
        '🗺️ Abriendo ruta desde ubicación actual (${currentLocation.latitude}, ${currentLocation.longitude}) hasta ($lat, $lng)',
      );

      // Abrir ruta desde ubicación actual hasta la dirección del cliente
      final bool success = await MapsService.openRouteInMaps(
        originLat: currentLocation.latitude,
        originLng: currentLocation.longitude,
        destinationLat: lat,
        destinationLng: lng,
        destinationLabel: cleanAddress,
      );

      if (!success) {
        print('❌ No se pudo abrir la aplicación de mapas');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la aplicación de mapas'),
          ),
        );
      }
    } catch (e) {
      print('❌ Error al abrir el mapa: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir el mapa: $e')));
    }
  }
}
