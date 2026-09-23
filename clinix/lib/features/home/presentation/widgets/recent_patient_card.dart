import 'package:flutter/material.dart';

class RecentPatientCard extends StatelessWidget {
  final String name;
  final String room;
  final String condition;
  final String status;
  final bool needsAttention;

  const RecentPatientCard({
    super.key,
    required this.name,
    required this.room,
    required this.condition,
    required this.status,
    this.needsAttention = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = needsAttention
        ? const Color(0xFFE04444)
        : const Color(0xFF18A567);

    final statusBackground = needsAttention
        ? const Color(0xFFFFEEEE)
        : const Color(0xFFEAF9F2);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.grey.shade500,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152A5B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$room  •  $condition',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667494),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF667494),
          ),
        ],
      ),
    );
  }
}