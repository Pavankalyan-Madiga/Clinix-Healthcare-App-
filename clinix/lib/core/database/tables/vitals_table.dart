import 'package:drift/drift.dart';

class Vitals extends Table {
  TextColumn get id => text()();

  TextColumn get patientId => text()();

  TextColumn get type => text()();

  TextColumn get value => text()();

  TextColumn get unit => text()();

  DateTimeColumn get recordedAt => dateTime()();

  TextColumn get recordedBy => text()();

  @override
  Set<Column> get primaryKey => {id};
}