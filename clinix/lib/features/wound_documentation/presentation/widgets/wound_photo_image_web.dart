import 'package:flutter/material.dart';

class WoundPhotoImage extends StatelessWidget {
  final String filePath;

  const WoundPhotoImage({
    super.key,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      filePath,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Color(0xFF9AA4B2),
          ),
        );
      },
    );
  }
}