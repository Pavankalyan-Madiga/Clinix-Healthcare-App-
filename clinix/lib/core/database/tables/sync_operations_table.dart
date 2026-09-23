import 'package:drift/drift.dart';

class SyncOperations extends Table {
  TextColumn get id => text()();

  TextColumn get operationId => text().unique()();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  TextColumn get operationType => text()();

  TextColumn get payload => text()();

  TextColumn get status => text()();

  IntColumn get retryCount =>
      integer().withDefault(
        const Constant(0),
      )();

  IntColumn get baseVersion =>
      integer().nullable()();

  TextColumn get lastError =>
      text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime()();

  DateTimeColumn get updatedAt =>
      dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}