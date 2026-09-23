import 'package:just_audio/just_audio.dart';

Future<Duration?> loadVoiceNote(
  AudioPlayer player,
  String path,
) {
  return player.setFilePath(path);
}