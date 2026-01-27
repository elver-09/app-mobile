import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'photo_view_dialog.dart';

class RejectOrderModal extends StatefulWidget {
  final String orderNumber;
  final String clientName;

  const RejectOrderModal({
    super.key,
    required this.orderNumber,
    required this.clientName,
  });

  @override
  State<RejectOrderModal> createState() => _RejectOrderModalState();
}

class _RejectOrderModalState extends State<RejectOrderModal> {
  String? selectedReason;
  final TextEditingController _commentController = TextEditingController();
  List<File> evidencePhotos = [];
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> rejectReasons = [
    'Cliente rechaza pedido',
    'Dirección incorrecta',
    'No responde / ausente',
    'Problema con acceso',
    'Otro motivo',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (evidencePhotos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 2 fotos permitidas')),
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
          evidencePhotos.add(File(photo.path));
        });
        print('📷 Foto de evidencia capturada: ${photo.path}');
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

  void _removePhoto(int index) {
    setState(() {
      evidencePhotos.removeAt(index);
    });
  }

  void _showPhotosDialog() {
    if (evidencePhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay fotos para mostrar')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PhotoViewDialog(
        photos: evidencePhotos,
        onDeletePhoto: (index) {
          setState(() {
            _removePhoto(index);
          });
        },
      ),
    );
  }

  bool _canConfirm() {
    return selectedReason != null && 
          _commentController.text.trim().isNotEmpty &&
          evidencePhotos.isNotEmpty;
  }

  void _confirmReject() {
    if (!_canConfirm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos requeridos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Retornar los datos al screen anterior
    Navigator.pop(context, {
      'reason': selectedReason,
      'comment': _commentController.text.trim(),
      'photos': evidencePhotos,
    });
  }

  Widget _buildReasonChip(String reason) {
    final isSelected = selectedReason == reason;
    return InkWell(
      onTap: () {
        setState(() {
          selectedReason = reason;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(color: const Color(0xFF10B981), width: 2)
              : null,
        ),
        child: Text(
          reason,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? const Color(0xFF059669) : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0F2FE),
          foregroundColor: const Color(0xFF0369A1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.orderNumber} · ${widget.clientName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Elige o escribe un motivo',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rejectReasons.map((reason) => _buildReasonChip(reason)).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Campo de texto
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Escribe el motivo del rechazo (obligatorio)',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
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
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    // Evidencia del intento
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Evidencia del intento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Máximo 2 fotos',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botones de foto
                    Row(
                      children: [
                        _buildActionButton(
                          label: 'Tomar foto',
                          icon: Icons.camera_alt,
                          onPressed: _takePhoto,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          label: 'Ver fotos',
                          icon: Icons.image,
                          onPressed: _showPhotosDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Preview de fotos en grid 2 columnas
                    if (evidencePhotos.isNotEmpty) ...[
                      Row(
                        children: [
                          if (evidencePhotos.isNotEmpty)
                            Expanded(
                              child: Container(
                                height: 150,
                                margin: EdgeInsets.only(right: evidencePhotos.length > 1 ? 8 : 0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                        onTap: () => _removePhoto(0),
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
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                        onTap: () => _removePhoto(1),
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
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Muestra puerta cerrada, timbre o señalización del lugar.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Resumen
                    const Text(
                      'Resumen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La orden ${widget.orderNumber} quedará como Rechazada y se cargará la siguiente parada optimizada.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer con botón
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _canConfirm() ? _confirmReject : null,
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Confirmar rechazo y continuar ruta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canConfirm() 
                            ? const Color(0xFFEF4444) 
                            : const Color(0xFFE5E7EB),
                        foregroundColor: _canConfirm() 
                            ? Colors.white 
                            : const Color(0xFF9CA3AF),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esta acción no se puede deshacer desde la app del conductor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
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
