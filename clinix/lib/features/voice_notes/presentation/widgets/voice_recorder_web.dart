import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

class VoiceRecorder extends StatefulWidget {
  final void Function(String path, int durationSeconds) onRecorded;

  const VoiceRecorder({
    super.key,
    required this.onRecorded,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _timer;

  bool _isRecording = false;
  int _seconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required.',
            ),
          ),
        );

        return;
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
        ),
        path: '',
      );

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _seconds = 0;
      });

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted) return;

          setState(() {
            _seconds++;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to start recording: $e',
          ),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      _timer = null;

      final duration = _seconds;

      final path = await _recorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      if (path != null && path.isNotEmpty) {
        widget.onRecorded(
          path,
          duration,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice note recorded (${_formatDuration(duration)})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to stop recording: $e',
          ),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60)
        .toString()
        .padLeft(2, '0');

    final remainingSeconds = (seconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8ECF2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _isRecording
                  ? const Color(0xFFFFEEEE)
                  : const Color(0xFFEAF4FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isRecording
                  ? Icons.mic
                  : Icons.mic_none,
              color: _isRecording
                  ? const Color(0xFFE04444)
                  : const Color(0xFF147DE5),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording
                ? _formatDuration(_seconds)
                : 'Record Voice Note',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152A5B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isRecording
                ? 'Recording in progress'
                : 'Tap the button to start recording',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF667494),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isRecording
                  ? _stopRecording
                  : _startRecording,
              icon: Icon(
                _isRecording
                    ? Icons.stop
                    : Icons.mic,
              ),
              label: Text(
                _isRecording
                    ? 'Stop Recording'
                    : 'Start Recording',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _isRecording
                    ? const Color(0xFFE04444)
                    : const Color(0xFF147DE5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}