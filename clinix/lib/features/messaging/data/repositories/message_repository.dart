import 'package:clinix/core/database/app_database.dart' as database;
import 'package:clinix/core/database/daos/message_dao.dart';
import 'package:clinix/core/sync/sync_queue.dart';
import 'package:clinix/features/messaging/data/domain/entites/message.dart';
import 'package:clinix/features/messaging/data/model/message_model.dart';
import 'package:drift/drift.dart';

class MessageRepository {
  final MessageDao _dao;
  final SyncQueue _syncQueue;

  MessageRepository(
    database.AppDatabase database,
    this._syncQueue,
  ) : _dao = database.messageDao;

  static String conversationIdFor(
    String firstStaffId,
    String secondStaffId,
  ) {
    final ids = [firstStaffId, secondStaffId]..sort();
    return '${ids[0]}__${ids[1]}';
  }

  Future<List<MessageModel>> getAllMessages() async {
    final messages = await _dao.getAllMessages();

    return messages
        .map(_toModel)
        .toList();
  }

  Stream<List<MessageModel>> watchAllMessages() {
    return _dao.watchAllMessages().map(
          (messages) => messages
              .map(_toModel)
              .toList(),
        );
  }

  Future<List<MessageModel>> getMessagesByConversationId(
    String conversationId,
  ) async {
    final messages =
        await _dao.getMessagesByConversationId(
      conversationId,
    );

    return messages
        .map(_toModel)
        .toList();
  }

  Stream<List<MessageModel>> watchMessagesByConversationId(
    String conversationId,
  ) {
    return _dao
        .watchMessagesByConversationId(conversationId)
        .map(
          (messages) => messages
              .map(_toModel)
              .toList(),
        );
  }

  Future<MessageModel?> getMessageById(
    String id,
  ) async {
    final message =
        await _dao.getMessageById(id);

    if (message == null) {
      return null;
    }

    return _toModel(message);
  }

  Future<void> sendMessage(
    MessageModel message,
  ) async {
    await _dao.insertMessage(
      database.MessagesCompanion.insert(
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        senderName: message.senderName,
        receiverId: message.receiverId,
        receiverName: message.receiverName,
        content: message.content,
        createdAt: message.createdAt,
        status: message.status.name,
        isRead: Value(message.isRead),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'MESSAGE',
      entityId: message.id,
      operationType: 'CREATE',
      payload: message.toJson(),
      baseVersion: 1,
    );
  }

  Future<void> markAsRead(
    String messageId,
  ) async {
    final existing =
        await _dao.getMessageById(messageId);

    if (existing == null) {
      return;
    }

    await _dao.updateMessage(
      database.MessagesCompanion(
        id: Value(messageId),
        conversationId:
            Value(existing.conversationId),
        senderId:
            Value(existing.senderId),
        senderName:
            Value(existing.senderName),
        receiverId:
            Value(existing.receiverId),
        receiverName:
            Value(existing.receiverName),
        content:
            Value(existing.content),
        createdAt:
            Value(existing.createdAt),
        status:
            Value(existing.status),
        isRead:
            const Value(true),
      ),
    );
  }

  Future<void> updateMessage(
    MessageModel message,
  ) async {
    await _dao.updateMessage(
      database.MessagesCompanion(
        id: Value(message.id),
        conversationId:
            Value(message.conversationId),
        senderId:
            Value(message.senderId),
        senderName:
            Value(message.senderName),
        receiverId:
            Value(message.receiverId),
        receiverName:
            Value(message.receiverName),
        content:
            Value(message.content),
        createdAt:
            Value(message.createdAt),
        status:
            Value(message.status.name),
        isRead:
            Value(message.isRead),
      ),
    );

    await _syncQueue.enqueue(
      entityType: 'MESSAGE',
      entityId: message.id,
      operationType: 'UPDATE',
      payload: message.toJson(),
      baseVersion: 1,
    );
  }

  Future<void> deleteMessage(
    String messageId,
  ) async {
    await _dao.deleteMessage(messageId);

    await _syncQueue.enqueue(
      entityType: 'MESSAGE',
      entityId: messageId,
      operationType: 'DELETE',
      payload: {
        'id': messageId,
      },
      baseVersion: 1,
    );
  }

  Future<void> deleteConversation(
    String conversationId,
  ) async {
    await _dao.deleteConversation(
      conversationId,
    );
  }

  MessageModel _toModel(
    database.Message message,
  ) {
    return MessageModel(
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      senderName: message.senderName,
      receiverId: message.receiverId,
      receiverName: message.receiverName,
      content: message.content,
      createdAt: message.createdAt,
      status: _parseStatus(message.status),
      isRead: message.isRead,
    );
  }

  MessageStatus _parseStatus(
    String status,
  ) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}