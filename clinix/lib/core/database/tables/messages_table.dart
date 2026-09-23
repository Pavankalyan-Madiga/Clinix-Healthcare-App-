import 'package:drift/drift.dart';

class Messages extends Table {
  TextColumn get id => text()();

  TextColumn get conversationId => text()();

  TextColumn get senderId => text()();

  TextColumn get senderName => text()();

  TextColumn get receiverId => text()();

  TextColumn get receiverName => text()();

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get status => text()();

  BoolColumn get isRead => boolean().withDefault(
        const Constant(false),
      )();

  @override
  Set<Column> get primaryKey => {id};
}