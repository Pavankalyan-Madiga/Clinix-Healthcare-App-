import 'package:clinix/features/notes/domain/entites/note.dart';
import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8ECF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  color: Color(0xFF147DE5),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  note.author,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF152A5B),
                  ),
                ),
              ),
              Text(
                note.createdAt,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF667494),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF152A5B),
            ),
          ),
        ],
      ),
    );
  }
}