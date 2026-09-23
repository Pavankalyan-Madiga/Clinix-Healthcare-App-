import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/messages_table.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase>
    with _$MessageDaoMixin {
  MessageDao(AppDatabase db) : super(db);

  Future<List<Message>> getAllMessages() {
    final query = select(messages)
      ..orderBy([
        (message) => OrderingTerm.asc(message.createdAt),
      ]);

    return query.get();
  }

  Stream<List<Message>> watchAllMessages() {
    final query = select(messages)
      ..orderBy([
        (message) => OrderingTerm.asc(message.createdAt),
      ]);

    return query.watch();
  }

  Future<List<Message>> getMessagesByConversationId(
    String conversationId,
  ) {
    final query = select(messages)
      ..where(
        (message) => message.conversationId.equals(conversationId),
      )
      ..orderBy([
        (message) => OrderingTerm.asc(message.createdAt),
      ]);

    return query.get();
  }

  Stream<List<Message>> watchMessagesByConversationId(
    String conversationId,
  ) {
    final query = select(messages)
      ..where(
        (message) => message.conversationId.equals(conversationId),
      )
      ..orderBy([
        (message) => OrderingTerm.asc(message.createdAt),
      ]);

    return query.watch();
  }

  Future<Message?> getMessageById(String id) {
    return (select(messages)
          ..where(
            (message) => message.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<void> insertMessage(MessagesCompanion message) async {
    await into(messages).insert(message);
  }

  Future<void> updateMessage(MessagesCompanion message) async {
    await update(messages).replace(message);
  }

  Future<void> deleteMessage(String id) async {
    await (delete(messages)
          ..where(
            (message) => message.id.equals(id),
          ))
        .go();
  }

  Future<void> deleteConversation(String conversationId) async {
    await (delete(messages)
          ..where(
            (message) => message.conversationId.equals(conversationId),
          ))
        .go();
  }
}