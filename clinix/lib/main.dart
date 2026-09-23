import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_seed.dart';
import 'providers/auth_providers.dart';
import 'providers/database_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences =
      await SharedPreferences.getInstance();

  final database = AppDatabase();

  await DatabaseSeed.seed(database);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider
            .overrideWithValue(preferences),
        databaseProvider
            .overrideWithValue(database),
      ],
      child: const ClinixApp(),
    ),
  );
}