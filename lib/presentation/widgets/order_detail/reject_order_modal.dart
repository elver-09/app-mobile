import 'package:flutter/material.dart';
import 'dart:io';
import 'photo_capture_widget.dart';

class RejectOrderModal extends StatefulWidget {
  final String orderNumber;
  final String clientName;
  final List<Map<String, dynamic>> rejectionReasons;

  const RejectOrderModal({
    super.key,
    required this.orderNumber,
    required this.clientName,
    required this.rejectionReasons,
  });

  @override
  State<RejectOrderModal> createState() => _RejectOrderModalState();
}

class _RejectOrderModalState extends State<RejectOrderModal> {
  int? selectedReasonId;
  String? selectedReasonName;
  final TextEditingController _commentController = TextEditingController();
  List<File> evidencePhotos = [];

  // Verificar si la razón seleccionada requiere nota
  bool _selectedReasonNeedsNote() {
    if (selectedReasonId == null) return false;
    final reason = widget.rejectionReasons.firstWhere(
      (r) => r['id'] == selectedReasonId,
      orElse: () => {},
    );
    return reason['need_note'] ?? false;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _canConfirm() {
    // Verificar que se seleccionó un motivo
    if (selectedReasonId == null) return false;
    
    // Verificar si la razón requiere nota
    final needsNote = _selectedReasonNeedsNote();
    
    if (needsNote) {
      return _commentController.text.trim().isNotEmpty &&
            evidencePhotos.length >= 3;
    }
    // Para otros motivos, solo se necesita motivo y evidencia
    return evidencePhotos.length >= 3;
  }

  void _confirmReject() {
    if (!_canConfirm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa los campos y captura 3 fotos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Retornar los datos al screen anterior
    Navigator.pop(context, {
      'reasonId': selectedReasonId,
      'reason': selectedReasonName,
      'comment': _commentController.text.trim(),
      'photos': evidencePhotos,
    });
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
          _commentController.clear(); // Limpiar el campo cuando cambia de motivo
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: const Color(0xFF0F766E), width: 2)
              : Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Text(
          reasonName,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getTextFieldHint() {
    if (selectedReasonName == null) {
      return 'Selecciona un motivo primero';
    }
    return 'Escribe detalles adicionales (obligatorio)';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 660),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirmar rechazo de la orden',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.orderNumber} · ${widget.clientName}',
                          style: const TextStyle(
                            fontSize: 12,
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
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Motivo del rechazo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Motivo del rechazo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Elige o escribe un motivo',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.rejectionReasons.map((reason) => _buildReasonChip(reason)).toList(),
                    ),
                    const SizedBox(height: 10),
                    // Campo de texto - Mostrar solo si se requiere nota por la razón
                    if (_selectedReasonNeedsNote()) ...[
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: _getTextFieldHint(),
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Evidencia del intento
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Evidencia del intento',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '3 fotos obligatorias',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Botones de foto
                    PhotoCaptureWidget(
                      photos: evidencePhotos,
                      onPhotoAdded: (photo) {
                        setState(() {
                          evidencePhotos.add(photo);
                        });
                      },
                      onPhotoRemoved: (index) {
                        setState(() {
                          evidencePhotos.removeAt(index);
                        });
                      },
                      maxPhotos: 3,
                      emptyMessage: 'No hay fotos para ver',
                    ),
                    const SizedBox(height: 8),
                    // Preview de fotos en grid 2 columnas
                    if (evidencePhotos.isNotEmpty) ...[
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 150,
                                  margin: EdgeInsets.only(right: evidencePhotos.length > 1 ? 8 : 0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          evidencePhotos[0],
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            evidencePhotos.removeAt(0);
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (evidencePhotos.length > 1)
                                Expanded(
                                  child: Container(
                                    height: 150,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            evidencePhotos[1],
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              evidencePhotos.removeAt(1);
                                            }),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (evidencePhotos.length > 2) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            evidencePhotos[2],
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              evidencePhotos.removeAt(2);
                                            }),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Muestra puerta cerrada, timbre o señalización del lugar.',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Resumen
                    const Text(
                      'Resumen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'La orden ${widget.orderNumber} quedará como Rechazada y se cargará la siguiente parada optimizada.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer con botón
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: _canConfirm() ? _confirmReject : null,
                      icon: const Icon(Icons.cancel, size: 14),
                      label: const Text(
                        'Confirmar rechazo',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canConfirm() 
                            ? const Color(0xFFB91C1C) 
                            : const Color(0xFFE2E8F0),
                        foregroundColor: _canConfirm() 
                            ? Colors.white 
                            : const Color(0xFF94A3B8),
                        elevation: 0,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Esta acción no se puede deshacer desde la app del conductor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
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
}
