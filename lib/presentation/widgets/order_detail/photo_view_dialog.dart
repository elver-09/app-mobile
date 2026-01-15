import 'dart:io';
import 'package:flutter/material.dart';

class PhotoViewDialog extends StatefulWidget {
  final List<File> photos;
  final Function(int) onDeletePhoto;

  const PhotoViewDialog({
    super.key,
    required this.photos,
    required this.onDeletePhoto,
  });

  @override
  State<PhotoViewDialog> createState() => _PhotoViewDialogState();
}

class _PhotoViewDialogState extends State<PhotoViewDialog> {
  late PageController _pageController;
  int _currentPage = 0;

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
    return Dialog(
      backgroundColor: Colors.black87,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Foto ${_currentPage + 1} de ${widget.photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(
                    widget.photos[index],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onDeletePhoto(_currentPage);
                    if (widget.photos.isEmpty) {
                      Navigator.of(context).pop();
                    } else if (_currentPage >= widget.photos.length) {
                      setState(() {
                        _currentPage = widget.photos.length - 1;
                      });
                      _pageController.jumpToPage(_currentPage);
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
