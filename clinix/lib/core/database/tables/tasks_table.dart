import 'package:drift/drift.dart';

class Tasks extends Table {
  TextColumn get id => text()();

  TextColumn get patientId => text()();

  TextColumn get title => text()();

  TextColumn get description => text()();

  TextColumn get assignedTo => text()();

  TextColumn get dueDate => text()();

  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}