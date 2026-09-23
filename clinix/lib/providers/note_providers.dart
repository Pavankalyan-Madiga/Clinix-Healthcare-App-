import 'package:clinix/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notes/data/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return NoteRepository(database);
});