import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveWoundPhoto(
  XFile pickedFile,
  String id,
) async {
  final documentsDirectory =
      await getApplicationDocumentsDirectory();

  final woundDirectory = Directory(
    p.join(
      documentsDirectory.path,
      'wound_photos',
    ),
  );

  if (!await woundDirectory.exists()) {
    await woundDirectory.create(
      recursive: true,
    );
  }

  final extension = p.extension(
    pickedFile.path,
  );

  final savedPath = p.join(
    woundDirectory.path,
    '$id$extension',
  );

  final savedFile = await File(
    pickedFile.path,
  ).copy(savedPath);

  return savedFile.path;
}

Future<void> deleteWoundPhotoFile(
  String filePath,
) async {
  final file = File(filePath);

  if (await file.exists()) {
    await file.delete();
  }
}