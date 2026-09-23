import 'dart:async';

import 'package:clinix/features/voice_notes/data/audio_playback.dart';
import 'package:clinix/features/voice_notes/data/model/voice_note_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../providers/sync_providers.dart';
import 'widgets/voice_recorder.dart';

class VoiceNotesPage extends ConsumerStatefulWidget {
  final String patientId;

  const VoiceNotesPage({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<VoiceNotesPage> createState() =>
      _VoiceNotesPageState();
}

class _VoiceNotesPageState
    extends ConsumerState<VoiceNotesPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<PlayerState>?
      _playerStateSubscription;

  String? _currentNoteId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _playerStateSubscription =
        _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPlaying = state.playing;

        if (state.processingState ==
            ProcessingState.completed) {
          _isPlaying = false;
          _currentNoteId = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(
      voiceNoteRepositoryProvider,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF152A5B),
          ),
        ),
        title: const Text(
          'Voice Notes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152A5B),
          ),
        ),
      ),
      body: StreamBuilder<List<VoiceNoteModel>>(
        stream: repository.watchVoiceNotesByPatient(
          widget.patientId,
        ),
        builder: (context, snapshot) {
          final voiceNotes = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                VoiceRecorder(
                  onRecorded: _saveVoiceNote,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Recorded Notes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152A5B),
                  ),
                ),
                const SizedBox(height: 12),
                if (voiceNotes.isEmpty)
                  _buildEmptyState()
                else
                  ...voiceNotes.map(
                    _buildVoiceNoteCard,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveVoiceNote(
    String path,
    int durationSeconds,
  ) async {
    final repository = ref.read(
      voiceNoteRepositoryProvider,
    );

    try {
      await repository.addVoiceNote(
        patientId: widget.patientId,
        filePath: path,
        durationSeconds: durationSeconds,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voice note successfully noted',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save voice note: $e',
          ),
        ),
      );
    }
  }

  Future<void> _togglePlayback(
    VoiceNoteModel note,
  ) async {
    try {
      if (_currentNoteId == note.id &&
          _isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      if (_currentNoteId == note.id) {
        await _audioPlayer.play();
        return;
      }

      await _audioPlayer.stop();

      final duration = await loadVoiceNote(
        _audioPlayer,
        note.filePath,
      );

      if (duration == null) {
        throw Exception(
          'Unable to read audio file.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _currentNoteId = note.id;
        _isPlaying = true;
      });

      await _audioPlayer.play();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentNoteId = null;
        _isPlaying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to play voice note: $e',
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8ECF2),
        ),
      ),
      child: const Center(
        child: Text(
          'No voice notes yet',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF667494),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceNoteCard(
    VoiceNoteModel note,
  ) {
    final isCurrentNote =
        _currentNoteId == note.id;

    final isPlaying =
        isCurrentNote && _isPlaying;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8ECF2),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _togglePlayback(note),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: const Color(0xFF147DE5),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF152A5B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(note.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667494),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(
                    note.durationSeconds,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667494),
                  ),
                ),
                if (isPlaying) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Playing',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF147DE5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}