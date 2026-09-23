import 'package:drift/drift.dart';

class Notes extends Table {
  TextColumn get id => text()();

  TextColumn get patientId => text()();

  TextColumn get content => text()();

  TextColumn get author => text()();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}