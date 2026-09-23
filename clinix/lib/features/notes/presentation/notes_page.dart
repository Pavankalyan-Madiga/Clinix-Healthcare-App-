import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/note_providers.dart';
import '../data/model/note_model.dart';
import 'add_note_page.dart';
import 'widgets/note_card.dart';

class NotesPage extends ConsumerStatefulWidget {
  final String patientId;

  const NotesPage({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  List<NoteModel> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final repository = ref.read(noteRepositoryProvider);

    final notes = await repository.getNotesByPatientId(
      widget.patientId,
    );

    if (!mounted) return;

    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _addNote() async {
    final note = await Navigator.push<NoteModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddNotePage(
          patientId: widget.patientId,
        ),
      ),
    );

    if (note == null || !mounted) {
      return;
    }

    setState(() {
      _notes.insert(0, note);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Clinical Notes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _notes.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    100,
                  ),
                  itemCount: _notes.length,
                  separatorBuilder: (_, _) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    return NoteCard(
                      note: _notes[index],
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No clinical notes yet',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF667494),
        ),
      ),
    );
  }
}