import 'dart:convert';

import 'package:image_picker/image_picker.dart';

Future<String> saveWoundPhoto(
  XFile pickedFile,
  String id,
) async {
  final bytes = await pickedFile.readAsBytes();

  final mimeType =
      pickedFile.mimeType ?? 'image/jpeg';

  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

Future<void> deleteWoundPhotoFile(
  String filePath,
) async {}