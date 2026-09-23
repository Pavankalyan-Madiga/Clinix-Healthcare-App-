import 'package:flutter/material.dart';

import '../../data/model/wound_photo_model.dart';
import 'wound_photo_image.dart';

class WoundPhotoCard extends StatelessWidget {
  final WoundPhotoModel photo;
  final VoidCallback onDelete;

  const WoundPhotoCard({
    super.key,
    required this.photo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: WoundPhotoImage(
              filePath: photo.filePath,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              8,
              14,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(
                          photo.capturedAt,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Captured by ${photo.capturedBy}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      if (photo.note.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          photo.note,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();

    final day =
        local.day.toString().padLeft(2, '0');

    final month =
        local.month.toString().padLeft(2, '0');

    final year = local.year;

    final hour =
        local.hour.toString().padLeft(2, '0');

    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }
}