import 'dart:io';
import 'package:flutter/material.dart';

class DeliveryPhotosWidget extends StatelessWidget {
  final List<File> photos;
  final int maxPhotos;
  final VoidCallback? onTakePhoto;
  final VoidCallback onViewPhotos;
  final Function(int) onRemovePhoto;

  const DeliveryPhotosWidget({
    super.key,
    required this.photos,
    required this.maxPhotos,
    this.onTakePhoto,
    required this.onViewPhotos,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: Color(0xFF0F172A),
                ),
              ),
              const Text(
                'Obligatoria para finalizar',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: _buildPhotoGrid(context),
          ),
          const SizedBox(height: 16),
          if (photos.isNotEmpty)
            Center(
              child: OutlinedButton.icon(
                onPressed: onViewPhotos,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Ver fotos'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: const BorderSide(color: Color(0xFF1D4ED8)),
                  foregroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    final photoBoxes = List.generate(
      maxPhotos,
      (index) => SizedBox(
        width: 150,
        child: _buildPhotoBox(context, index),
      ),
    );

    if (maxPhotos <= 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < photoBoxes.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            photoBoxes[i],
          ],
        ],
      );
    }

    if (maxPhotos == 3) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              photoBoxes[0],
              const SizedBox(width: 12),
              photoBoxes[1],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [photoBoxes[2]],
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: photoBoxes,
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      color: Color(0xFF94A3B8),
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
                    color: Color(0xFFB91C1C),
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
