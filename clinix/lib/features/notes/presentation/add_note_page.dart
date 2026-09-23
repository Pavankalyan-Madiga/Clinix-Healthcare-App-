import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/note_providers.dart';
import '../data/model/note_model.dart';

class AddNotePage extends ConsumerStatefulWidget {
  final String patientId;

  const AddNotePage({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends ConsumerState<AddNotePage> {
  final TextEditingController _controller = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final content = _controller.text.trim();

    if (content.isEmpty || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final note = NoteModel(
      id: 'N-${DateTime.now().millisecondsSinceEpoch}',
      patientId: widget.patientId,
      content: content,
      author: 'Clinical Staff',
      createdAt: DateTime.now().toIso8601String(),
    );

    final repository = ref.read(noteRepositoryProvider);

    await repository.addNote(note);

    if (!mounted) return;

    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Add Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 7,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Enter clinical note',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFFE8ECF2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFFE8ECF2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFF147DE5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _saveNote,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Note'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}