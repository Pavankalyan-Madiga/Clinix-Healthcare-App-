
import 'package:clinix/features/messaging/data/domain/entites/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderName,
    required super.receiverId,
    required super.receiverName,
    required super.content,
    required super.createdAt,
    required super.status,
    required super.isRead,
  });

  factory MessageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      conversationId:
          json['conversation_id']?.toString() ?? '',
      senderId:
          json['sender_id']?.toString() ?? '',
      senderName:
          json['sender_name']?.toString() ?? '',
      receiverId:
          json['receiver_id']?.toString() ?? '',
      receiverName:
          json['receiver_name']?.toString() ?? '',
      content:
          json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (value) =>
            value.name ==
            json['status']?.toString(),
        orElse: () =>
            MessageStatus.sent,
      ),
      isRead:
          json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'content': content,
      'created_at':
          createdAt.toIso8601String(),
      'status': status.name,
      'is_read': isRead,
    };
  }

  @override
  MessageModel copyWith({
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
    return MessageModel(
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