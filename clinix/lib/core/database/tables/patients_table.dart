import 'package:drift/drift.dart';

class Patients extends Table {
  TextColumn get id => text()();

  TextColumn get firstName => text()();

  TextColumn get lastName => text()();

  TextColumn get dateOfBirth => text()();

  TextColumn get gender => text()();

  TextColumn get room => text()();

  TextColumn get condition => text()();

  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}