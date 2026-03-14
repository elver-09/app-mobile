import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MultipleDeliveryModal extends StatefulWidget {
  final GroupedOrder groupedOrder;
  final String actionType; // 'deliver' o 'reject'
  final OdooClient odooClient;
  final String token;

  const MultipleDeliveryModal({
    super.key,
    required this.groupedOrder,
    required this.actionType,
    required this.odooClient,
    required this.token,
  });

  @override
  State<MultipleDeliveryModal> createState() =>
      _MultipleDeliveryModalState();
}

class _MultipleDeliveryModalState extends State<MultipleDeliveryModal> {
  List<File> photos = [];
  final TextEditingController _commentController = TextEditingController();
  int? selectedReasonId;
  String? selectedReasonName;
  bool _isLoadingReasons = true;
  List<Map<String, dynamic>> rejectionReasons = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Si es rechazo, cargar razones
    if (widget.actionType == 'reject') {
      _loadRejectionReasons();
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
          _isLoadingReasons = false;
        });
        print('✅ Razones de rechazo cargadas: ${reasons.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReasons = false;
        });
        print('❌ Error al cargar razones de rechazo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar razones de rechazo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _selectedReasonNeedsNote() {
    if (selectedReasonId == null) return false;
    final reason = rejectionReasons.firstWhere(
      (r) => r['id'] == selectedReasonId,
      orElse: () => {},
    );
    return reason['need_note'] ?? false;
  }

  Future<void> _takePhoto(int maxPhotos) async {
    if (photos.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo $maxPhotos foto${maxPhotos > 1 ? 's' : ''} permitida${maxPhotos > 1 ? 's' : ''}'),
        ),
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
          photos.add(File(photo.path));
        });
        print('📷 Foto capturada: ${photo.path}');
      }
    } catch (e) {
      print('❌ Error al capturar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar foto: $e')),
        );
      }
    }
  }

  bool get _canConfirm {
    if (widget.actionType == 'deliver') {
      // Para entrega, necesita 3 fotos
      return photos.length >= 3;
    } else {
      // Para rechazo, necesita 3 fotos y motivo
      bool hasPhotos = photos.length >= 3;
      bool hasReason = selectedReasonId != null;
      bool hasComment =
          _selectedReasonNeedsNote() ? _commentController.text.trim().isNotEmpty : true;

      return hasPhotos && hasReason && hasComment;
    }
  }

  void _confirmMultipleDelivery() {
    if (!_canConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.actionType == 'deliver'
              ? 'Por favor captura las 3 fotos obligatorias'
              : 'Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.actionType == 'deliver') {
      Navigator.pop(context, {
        'type': 'multiple_delivery',
        'orders': widget.groupedOrder.orders,
        'photos': photos,
        'comment': _commentController.text.trim(),
      });
    } else {
      Navigator.pop(context, {
        'type': 'multiple_reject',
        'orders': widget.groupedOrder.orders,
        'reasonId': selectedReasonId,
        'reason': selectedReasonName,
        'comment': _commentController.text.trim(),
        'photos': photos,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivery = widget.actionType == 'deliver';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDelivery
                      ? const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]
                      : const [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivery
                              ? 'Entregar todas las órdenes'
                              : 'Rechazar todas las órdenes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDelivery
                                ? const Color(0xFF166534)
                                : const Color(0xFF7F1D1D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.groupedOrder.clientName} · ${widget.groupedOrder.orders.length} órdenes',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: const Color(0xFF334155),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lista de órdenes
                    const Text(
                      'Órdenes a procesar:',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.groupedOrder.orders.map((order) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                isDelivery
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: isDelivery
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.orderNumber,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      order.product ?? 'Sin producto',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Campos específicos por tipo
                    if (!isDelivery) ...[
                      const Text(
                        'Motivo del rechazo',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingReasons)
                        const Center(child: CircularProgressIndicator())
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: rejectionReasons
                              .map((reason) => _buildReasonChip(reason))
                              .toList(),
                        ),
                      const SizedBox(height: 16),
                      if (_selectedReasonNeedsNote()) ...[
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Detalles adicionales (obligatorio)',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFB91C1C), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                    // Fotos
                    Text(
                      isDelivery
                          ? 'Evidencia de entrega'
                          : 'Evidencia del rechazo',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isDelivery
                          ? '3 fotos obligatorias'
                          : '3 fotos obligatorias',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (photos.length < 3)
                      SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _takePhoto(3);
                          },
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: Text(
                            'Capturar foto (${photos.length}/3)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDelivery
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            side: BorderSide(
                              color: isDelivery
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              width: 1.2,
                            ),
                            backgroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: FileImage(photos[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 3,
                                right: 3,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      photos.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    // Eliminado: texto de muestra puerta cerrada, timbre o señalización del lugar
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 180,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _canConfirm ? _confirmMultipleDelivery : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canConfirm
                            ? (isDelivery
                                ? const Color(0xFF10B981)
                                : const Color(0xFFB91C1C))
                            : const Color(0xFFE2E8F0),
                        foregroundColor: _canConfirm
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta acción no se puede deshacer desde la app del conductor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonChip(Map<String, dynamic> reason) {
    final reasonId = reason['id'] as int;
    final reasonName = reason['name'] as String;
    final isSelected = selectedReasonId == reasonId;

    return InkWell(
      onTap: () {
        setState(() {
          selectedReasonId = reasonId;
          selectedReasonName = reasonName;
          _commentController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF0F766E), width: 2)
              : Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          reasonName,
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? const Color(0xFF0F766E)
                : const Color(0xFF334155),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
