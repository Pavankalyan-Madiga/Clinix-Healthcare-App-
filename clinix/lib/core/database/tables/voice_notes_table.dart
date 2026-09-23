import 'package:drift/drift.dart';

class VoiceNotes extends Table {
  TextColumn get id => text()();

  TextColumn get patientId => text()();

  TextColumn get filePath => text()();

  DateTimeColumn get createdAt => dateTime()();

  IntColumn get durationSeconds => integer()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}