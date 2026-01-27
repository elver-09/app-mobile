import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'photo_view_dialog.dart';

class LossReportModal extends StatefulWidget {
  final String orderNumber;
  final String clientName;

  const LossReportModal({
    super.key,
    required this.orderNumber,
    required this.clientName,
  });

  @override
  State<LossReportModal> createState() => _LossReportModalState();
}

class _LossReportModalState extends State<LossReportModal> {
  final TextEditingController _damageDescriptionController = TextEditingController();
  List<File> evidencePhotos = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _damageDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          evidencePhotos.add(File(photo.path));
        });
        print('📷 Foto de siniestro capturada: ${photo.path}');
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

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          evidencePhotos.add(File(photo.path));
        });
        print('🖼️ Foto seleccionada de galería: ${photo.path}');
      }
    } catch (e) {
      print('❌ Error al seleccionar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar foto: $e')),
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
    return _damageDescriptionController.text.trim().isNotEmpty && 
           evidencePhotos.isNotEmpty;
  }

  void _confirmLossReport() {
    if (!_canConfirm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa descripción y captura al menos una foto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Retornar los datos del siniestro
    Navigator.pop(context, {
      'damageDescription': _damageDescriptionController.text.trim(),
      'photos': evidencePhotos,
    });
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
                          'Reportar siniestro',
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
                    const Text(
                      'Acción: REPORTAR SINIESTRO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Describe el daño o pérdida',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _damageDescriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe el daño, pérdida o incidente ocurrido (obligatorio)',
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
                    // Evidencia fotográfica
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Evidencia fotográfica',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Mínimo 1 foto',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botones de foto - Primera fila
                    Row(
                      children: [
                        _buildActionButton(
                          label: 'Tomar foto',
                          icon: Icons.camera_alt,
                          onPressed: _takePhoto,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          label: 'Galería',
                          icon: Icons.image,
                          onPressed: _pickFromGallery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botones de foto - Segunda fila
                    SizedBox(
                      width: double.infinity,
                      child: _buildActionButton(
                        label: 'Ver fotos',
                        icon: Icons.photo_library,
                        onPressed: _showPhotosDialog,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Preview de fotos en grid
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
                      'Captura fotos del daño, embalaje y estado del paquete.',
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
                      'La orden ${widget.orderNumber} quedará como Siniestrada y será enviada a investigación.',
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canConfirm() ? _confirmLossReport : null,
                  icon: const Icon(Icons.warning_outlined, size: 20),
                  label: const Text('Confirmar reporte de siniestro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canConfirm() 
                        ? const Color(0xFF6366F1) 
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
            ),
          ],
        ),
      ),
    );
  }
}
