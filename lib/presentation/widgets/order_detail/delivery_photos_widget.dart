import 'dart:io';
import 'package:flutter/material.dart';

class DeliveryPhotosWidget extends StatelessWidget {
  final List<File> photos;
  final int maxPhotos;
  final VoidCallback onTakePhoto;
  final VoidCallback onViewPhotos;
  final Function(int) onRemovePhoto;

  const DeliveryPhotosWidget({
    super.key,
    required this.photos,
    required this.maxPhotos,
    required this.onTakePhoto,
    required this.onViewPhotos,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Evidencia de entrega',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'Obligatoria para finalizar',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ...List.generate(
                maxPhotos,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < maxPhotos - 1 ? 12 : 0),
                    child: _buildPhotoBox(context, index),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: photos.length >= maxPhotos ? null : onTakePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Tomar foto'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    foregroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: photos.isEmpty ? null : onViewPhotos,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Ver fotos'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    foregroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildPhotoBox(BuildContext context, int index) {
    final hasPhoto = index < photos.length;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              image: hasPhoto
                  ? DecorationImage(
                      image: FileImage(photos[index]),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasPhoto
                ? null
                : const Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
          ),
          if (hasPhoto)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemovePhoto(index),
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
      ),
    );
  }
}
