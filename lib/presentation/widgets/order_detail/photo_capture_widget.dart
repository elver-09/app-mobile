import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PhotoCaptureWidget extends StatefulWidget {
  final List<File> photos;
  final Function(File) onPhotoAdded;
  final Function(int) onPhotoRemoved;
  final int maxPhotos;
  final String emptyMessage;

  const PhotoCaptureWidget({
    super.key,
    required this.photos,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    this.maxPhotos = 2,
    this.emptyMessage = 'No hay fotos para ver',
  });

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _takePhoto() async {
    if (widget.photos.length >= widget.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo ${widget.maxPhotos} fotos permitidas'),
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
        widget.onPhotoAdded(File(photo.path));
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

  void _viewPhotos() {
    if (widget.photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.emptyMessage),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: PhotoViewerModal(photos: widget.photos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Tomar foto',
            icon: Icons.camera_alt,
            onPressed: _takePhoto,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            label: 'Ver foto',
            icon: Icons.image,
            onPressed: _viewPhotos,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PhotoViewerModal extends StatefulWidget {
  final List<File> photos;

  const PhotoViewerModal({
    super.key,
    required this.photos,
  });

  @override
  State<PhotoViewerModal> createState() => _PhotoViewerModalState();
}

class _PhotoViewerModalState extends State<PhotoViewerModal> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black87,
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 500,
                width: MediaQuery.of(context).size.width * 0.9,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: widget.photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.photos[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${_currentIndex + 1} / ${widget.photos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
