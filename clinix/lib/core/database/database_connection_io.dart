import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

DatabaseConnection openDatabaseConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final directory =
          await getApplicationDocumentsDirectory();

      final file = File(
        p.join(
          directory.path,
          'clinix.sqlite',
        ),
      );

      final executor =
          NativeDatabase.createInBackground(file);

      return DatabaseConnection(executor);
    }),
  );
}