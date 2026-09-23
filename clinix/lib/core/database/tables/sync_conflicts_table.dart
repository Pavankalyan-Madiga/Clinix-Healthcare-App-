import 'package:drift/drift.dart';

class SyncConflicts extends Table {
  TextColumn get id => text()();

  TextColumn get operationId => text().unique()();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  IntColumn get clientVersion => integer()();

  IntColumn get serverVersion => integer()();

  TextColumn get clientPayload => text().nullable()();

  TextColumn get serverPayload => text().nullable()();

  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}