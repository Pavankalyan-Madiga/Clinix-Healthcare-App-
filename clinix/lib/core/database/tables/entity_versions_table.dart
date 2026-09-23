import 'package:drift/drift.dart';

class EntityVersions extends Table {
  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  IntColumn get version =>
      integer().withDefault(const Constant(1))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {
        entityType,
        entityId,
      };
}