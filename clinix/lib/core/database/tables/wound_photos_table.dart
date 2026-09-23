import 'package:drift/drift.dart';

class WoundPhotos extends Table {
  TextColumn get id => text()();

  TextColumn get patientId => text()();

  TextColumn get filePath => text()();

  TextColumn get serverFilePath =>
      text().withDefault(const Constant(''))();

  TextColumn get note => text()();

  DateTimeColumn get capturedAt =>
      dateTime()();

  TextColumn get capturedBy => text()();

  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}