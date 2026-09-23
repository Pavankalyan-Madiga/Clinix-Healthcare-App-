enum MessageStatus {
  sending,
  sent,
  failed,
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.content,
    required this.createdAt,
    required this.status,
    required this.isRead,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId:
          conversationId ?? this.conversationId,
      senderId:
          senderId ?? this.senderId,
      senderName:
          senderName ?? this.senderName,
      receiverId:
          receiverId ?? this.receiverId,
      receiverName:
          receiverName ?? this.receiverName,
      content:
          content ?? this.content,
      createdAt:
          createdAt ?? this.createdAt,
      status:
          status ?? this.status,
      isRead:
          isRead ?? this.isRead,
    );
  }
}