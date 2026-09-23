import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMine;
  final bool isSending;
  final bool isFailed;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMine,
    this.isSending = false,
    this.isFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: EdgeInsets.only(
          left: isMine ? 60 : 16,
          right: isMine ? 16 : 60,
          bottom: 8,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF147DE5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: const Color(0xFFE8ECF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: isMine ? Colors.white : const Color(0xFF152A5B),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF8A96AA),
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 5),
                  Icon(
                    isFailed
                        ? Icons.error_outline
                        : isSending
                        ? Icons.schedule
                        : Icons.done_all,
                    size: 14,
                    color: isFailed
                        ? const Color(0xFFFFD5D5)
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
