import 'package:flutter/material.dart';
import 'package:trainyl_2_0/core/odoo/order_model.dart';
import 'package:trainyl_2_0/core/odoo/odoo_client.dart';
import 'package:trainyl_2_0/core/responsive/responsive_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PartialDeliveryModal extends StatefulWidget {
  final GroupedOrder groupedOrder;
  final OdooClient odooClient;
  final String token;

  const PartialDeliveryModal({
    super.key,
    required this.groupedOrder,
    required this.odooClient,
    required this.token,
  });

  @override
  State<PartialDeliveryModal> createState() => _PartialDeliveryModalState();
}

class _PartialDeliveryModalState extends State<PartialDeliveryModal> {
  // Almacenar selecciones por orden
  Map<int, String> orderSelections = {}; // id -> 'deliver' o 'reject'
  
  // Fotos por tipo de acción
  List<File> deliveryPhotos = [];
  List<File> rejectionPhotos = [];
  
  // Datos de rechazo
  int? selectedReasonId;
  String? selectedReasonName;
  final TextEditingController _rejectCommentController =
      TextEditingController();
  List<Map<String, dynamic>> rejectionReasons = [];
  bool _isLoadingReasons = true;

  // Datos de entrega
  final TextEditingController _deliveryCommentController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Inicializar todas las órdenes como pendientes de selección
    for (final order in widget.groupedOrder.orders) {
      orderSelections[order.id] = 'pending';
    }
    // Cargar razones de rechazo
    _loadRejectionReasons();
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

  bool _selectedReasonNeedsNote() {
    if (selectedReasonId == null) return false;
    final reason = rejectionReasons.firstWhere(
      (r) => r['id'] == selectedReasonId,
      orElse: () => {},
    );
    return reason['need_note'] ?? false;
  }

  @override
  void dispose() {
    _rejectCommentController.dispose();
    _deliveryCommentController.dispose();
    super.dispose();
  }

  bool get _hasDeliveries =>
      orderSelections.values.where((v) => v == 'deliver').isNotEmpty;

  bool get _hasRejections =>
      orderSelections.values.where((v) => v == 'reject').isNotEmpty;

  bool get _allSelected =>
      orderSelections.values.every((v) => v != 'pending');

  bool get _canConfirm {
    if (!_allSelected) return false;

    // Si hay entregas, necesita 3 fotos
    if (_hasDeliveries && deliveryPhotos.length < 3) return false;

    // Si hay rechazos, necesita 3 fotos y motivo
    if (_hasRejections) {
      if (rejectionPhotos.length < 3) return false;
      if (selectedReasonId == null) return false;
      // Si la razón requiere nota, validar que haya comentario
      if (_selectedReasonNeedsNote() && _rejectCommentController.text.trim().isEmpty) {
        return false;
      }
    }

    return true;
  }

  void _confirmPartialDelivery() {
    if (!_canConfirm) {
      String message = 'Por favor completa todas las selecciones';
      if (_hasDeliveries && deliveryPhotos.length < 3) {
        message = 'Las entregas requieren 3 fotos obligatorias';
      } else if (_hasRejections && rejectionPhotos.length < 3) {
        message = 'Los rechazos requieren 3 fotos obligatorias';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ordersToDeliver = widget.groupedOrder.orders
        .where((o) => orderSelections[o.id] == 'deliver')
        .toList();

    final ordersToReject = widget.groupedOrder.orders
        .where((o) => orderSelections[o.id] == 'reject')
        .toList();

    Navigator.pop(context, {
      'type': 'partial_delivery',
      'ordersToDeliver': ordersToDeliver,
      'ordersToReject': ordersToReject,
      'deliveryPhotos': deliveryPhotos,
      'deliveryComment': _deliveryCommentController.text.trim(),
      'rejectionPhotos': rejectionPhotos,
      'rejectionReason': selectedReasonId,
      'rejectionReasonName': selectedReasonName,
      'rejectionComment': _rejectCommentController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
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
                        const Text(
                          'Entrega parcial',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.groupedOrder.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
                    // Seleccionar órdenes
                    const Text(
                      'Selecciona qué hacer con cada orden',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.groupedOrder.orders.map((order) {
                      final selection = orderSelections[order.id] ?? 'pending';
                      return _buildOrderSelection(order, selection, responsive);
                    }),
                    const SizedBox(height: 24),
                    // Fotos de entrega
                    if (_hasDeliveries) ...[
                      const Text(
                        'Evidencia de entregas',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Captura de foto (3 obligatorias)
                      _buildPhotoCapture(
                        label: 'Fotos de entrega (3 obligatorias)',
                        photos: deliveryPhotos,
                        onPhotoAdded: (photo) {
                          setState(() {
                            deliveryPhotos.add(photo);
                          });
                        },
                        onPhotoRemoved: (index) {
                          setState(() {
                            deliveryPhotos.removeAt(index);
                          });
                        },
                        maxPhotos: 3,
                        responsive: responsive,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _deliveryCommentController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Notas de entrega (opcional)',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF10B981), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Fotos de rechazo
                    if (_hasRejections) ...[
                      const Text(
                        'Evidencia de rechazos',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Motivo del rechazo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: _rejectCommentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Detalles adicionales del rechazo (obligatorio)',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
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
                      const SizedBox(height: 12),
                      _buildPhotoCapture(
                        label: 'Fotos de rechazo (3 obligatorias)',
                        photos: rejectionPhotos,
                        onPhotoAdded: (photo) {
                          setState(() {
                            rejectionPhotos.add(photo);
                          });
                        },
                        onPhotoRemoved: (index) {
                          setState(() {
                            rejectionPhotos.removeAt(index);
                          });
                        },
                        maxPhotos: 3,
                        responsive: responsive,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canConfirm ? _confirmPartialDelivery : null,
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canConfirm
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                    foregroundColor: _canConfirm
                        ? Colors.white
                        : const Color(0xFF94A3B8),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSelection(
    OrderItem order,
    String selection,
    ResponsiveHelper responsive,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.product ?? 'Sin producto',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      orderSelections[order.id] = 'deliver';
                    });
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Entregar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selection == 'deliver'
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                    side: BorderSide(
                      color: selection == 'deliver'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    backgroundColor: selection == 'deliver'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      orderSelections[order.id] = 'reject';
                    });
                  },
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selection == 'reject'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF94A3B8),
                    side: BorderSide(
                      color: selection == 'reject'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    backgroundColor: selection == 'reject'
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCapture({
    required String label,
    required List<File> photos,
    required Function(File) onPhotoAdded,
    required Function(int) onPhotoRemoved,
    int maxPhotos = 1,
    required ResponsiveHelper responsive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        // Botón para capturar foto
        if (photos.length < maxPhotos)
          OutlinedButton.icon(
            onPressed: () async {
              await _takePhoto(photos, onPhotoAdded, maxPhotos);
            },
            icon: const Icon(Icons.camera_alt),
            label: Text('Capturar foto (${photos.length}/$maxPhotos)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF94A3B8), width: 1.4),
              backgroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
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
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: DecorationImage(
                        image: FileImage(photos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onPhotoRemoved(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
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
      ],
    );
  }

  Future<void> _takePhoto(
    List<File> photos,
    Function(File) onPhotoAdded,
    int maxPhotos,
  ) async {
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
        onPhotoAdded(File(photo.path));
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

  Widget _buildReasonChip(Map<String, dynamic> reason) {
    final reasonId = reason['id'] as int;
    final reasonName = reason['name'] as String;
    final isSelected = selectedReasonId == reasonId;

    return InkWell(
      onTap: () {
        setState(() {
          selectedReasonId = reasonId;
          selectedReasonName = reasonName;
          _rejectCommentController.clear();
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
