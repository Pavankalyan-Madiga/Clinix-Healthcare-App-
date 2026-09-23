import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

DatabaseConnection openDatabaseConnection() {
  return DatabaseConnection.delayed(
    WasmDatabase.open(
      databaseName: 'clinix',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    ).then(
      (result) => DatabaseConnection(
        result.resolvedExecutor,
      ),
    ),
  );
}