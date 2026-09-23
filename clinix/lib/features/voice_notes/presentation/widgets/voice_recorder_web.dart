import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _timer;

  final List<int> _audioBytes = [];

  bool _isRecording = false;
  int _seconds = 0;

  static const int _sampleRate = 44100;
  static const int _channels = 1;
  static const int _bitsPerSample = 16;

  @override
  void dispose() {
    _timer?.cancel();
    _audioSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission =
          await _recorder.hasPermission();

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

      _audioBytes.clear();

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: _channels,
        ),
      );

      _audioSubscription = stream.listen(
        (data) {
          _audioBytes.addAll(data);
        },
        onError: (error) {
          debugPrint(
            'Voice recording stream error: $error',
          );
        },
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

      await _recorder.stop();

      await _audioSubscription?.cancel();
      _audioSubscription = null;

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      if (_audioBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No audio data was recorded.',
            ),
          ),
        );

        return;
      }

      final wavBytes = _createWavFile(
        Uint8List.fromList(_audioBytes),
      );

      final dataUrl =
          'data:audio/wav;base64,${base64Encode(wavBytes)}';

      widget.onRecorded(
        dataUrl,
        duration,
      );

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

  Uint8List _createWavFile(Uint8List pcmData) {
    final byteRate =
        _sampleRate *
        _channels *
        (_bitsPerSample ~/ 8);

    final blockAlign =
        _channels *
        (_bitsPerSample ~/ 8);

    final fileSize = 36 + pcmData.length;

    final buffer = ByteData(44);

    buffer.setUint32(
      0,
      0x52494646,
      Endian.big,
    );

    buffer.setUint32(
      4,
      fileSize,
      Endian.little,
    );

    buffer.setUint32(
      8,
      0x57415645,
      Endian.big,
    );

    buffer.setUint32(
      12,
      0x666d7420,
      Endian.big,
    );

    buffer.setUint32(
      16,
      16,
      Endian.little,
    );

    buffer.setUint16(
      20,
      1,
      Endian.little,
    );

    buffer.setUint16(
      22,
      _channels,
      Endian.little,
    );

    buffer.setUint32(
      24,
      _sampleRate,
      Endian.little,
    );

    buffer.setUint32(
      28,
      byteRate,
      Endian.little,
    );

    buffer.setUint16(
      32,
      blockAlign,
      Endian.little,
    );

    buffer.setUint16(
      34,
      _bitsPerSample,
      Endian.little,
    );

    buffer.setUint32(
      36,
      0x64617461,
      Endian.big,
    );

    buffer.setUint32(
      40,
      pcmData.length,
      Endian.little,
    );

    final result = BytesBuilder();

    result.add(buffer.buffer.asUint8List());
    result.add(pcmData);

    return result.toBytes();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60)
        .toString()
        .padLeft(2, '0');

    final remainingSeconds =
        (seconds % 60)
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
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}