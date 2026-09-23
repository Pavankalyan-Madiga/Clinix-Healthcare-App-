import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/wound_photo_providers.dart';
import '../data/model/wound_photo_model.dart';
import '../data/wound_photo_storage.dart';
import 'widgets/wound_photo_card.dart';

class WoundPhotosPage extends ConsumerStatefulWidget {
  final String patientId;

  const WoundPhotosPage({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<WoundPhotosPage> createState() =>
      _WoundPhotosPageState();
}

class _WoundPhotosPageState
    extends ConsumerState<WoundPhotosPage> {
  final ImagePicker _picker = ImagePicker();

  List<WoundPhotoModel> _photos = [];

  bool _isLoading = true;
  bool _isCapturing = false;
  bool _showingNoteDialog = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final repository =
        ref.read(woundPhotoRepositoryProvider);

    final photos =
        await repository.getWoundPhotosByPatientId(
      widget.patientId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _photos = photos;
      _isLoading = false;
    });
  }

  Future<void> _waitForNextFrame() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing ||
        _showingNoteDialog ||
        !mounted) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    XFile? pickedFile;

    try {
      pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCapturing = false;
      });

      await _waitForNextFrame();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open camera: $error',
          ),
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    if (pickedFile == null) {
      setState(() {
        _isCapturing = false;
      });

      return;
    }

    try {
      await _waitForNextFrame();

      if (!mounted) {
        return;
      }

      final id =
          'WOUND-${DateTime.now().microsecondsSinceEpoch}';

      final savedPath = await saveWoundPhoto(
        pickedFile,
        id,
      );

      final photo = WoundPhotoModel(
        id: id,
        patientId: widget.patientId,
        filePath: savedPath,
        serverFilePath: '',
        note: '',
        capturedAt: DateTime.now(),
        capturedBy: 'Clinical Staff',
        status: 'pending',
      );

      await ref
          .read(woundPhotoRepositoryProvider)
          .addWoundPhoto(photo);

      if (!mounted) {
        return;
      }

      setState(() {
        _photos.insert(0, photo);
        _isCapturing = false;
      });

      await _waitForNextFrame();

      if (!mounted) {
        return;
      }

      await _showNoteDialog(photo);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCapturing = false;
      });

      await _waitForNextFrame();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save photo: $error',
          ),
        ),
      );
    }
  }

  Future<void> _showNoteDialog(
    WoundPhotoModel photo,
  ) async {
    if (!mounted || _showingNoteDialog) {
      return;
    }

    _showingNoteDialog = true;

    final controller = TextEditingController();

    String? note;

    try {
      note = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add note'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Describe the wound or observation',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Skip'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    controller.text.trim(),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
      _showingNoteDialog = false;
    }

    if (!mounted || note == null) {
      return;
    }

    final trimmedNote = note.trim();

    if (trimmedNote.isEmpty) {
      return;
    }

    final updatedPhoto = WoundPhotoModel(
      id: photo.id,
      patientId: photo.patientId,
      filePath: photo.filePath,
      serverFilePath: photo.serverFilePath,
      note: trimmedNote,
      capturedAt: photo.capturedAt,
      capturedBy: photo.capturedBy,
      status: photo.status,
    );

    await ref
        .read(woundPhotoRepositoryProvider)
        .updateWoundPhoto(updatedPhoto);

    if (!mounted) {
      return;
    }

    setState(() {
      final index = _photos.indexWhere(
        (item) => item.id == photo.id,
      );

      if (index != -1) {
        _photos[index] = updatedPhoto;
      }
    });
  }

  Future<void> _deletePhoto(
    WoundPhotoModel photo,
  ) async {
    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete photo?'),
          content: const Text(
            'This wound photo will be removed from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await ref
        .read(woundPhotoRepositoryProvider)
        .deleteWoundPhoto(photo.id);

    await deleteWoundPhotoFile(
      photo.filePath,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _photos.removeWhere(
        (item) => item.id == photo.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wound Photos'),
      ),
      body: _buildBody(),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _isCapturing || _showingNoteDialog
                ? null
                : _capturePhoto,
        icon: _isCapturing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.camera_alt_outlined,
              ),
        label: Text(
          _isCapturing
              ? 'Opening camera...'
              : 'Take Photo',
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_photos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 56,
              ),
              SizedBox(height: 16),
              Text(
                'No wound photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Take a photo to document the patient wound.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        100,
      ),
      itemCount: _photos.length,
      separatorBuilder: (
        context,
        index,
      ) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (
        context,
        index,
      ) {
        final photo = _photos[index];

        return WoundPhotoCard(
          photo: photo,
          onDelete: () => _deletePhoto(photo),
        );
      },
    );
  }
}