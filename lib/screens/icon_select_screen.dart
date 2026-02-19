import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/image_picker_channel.dart';

/// S04: Icon selection screen.
/// Shown when the user taps the avatar in [ChildEditScreen].
///
/// [childId] is used to derive the save path for the icon image.
/// Returns the saved file path (String) via Navigator.pop, or null if cancelled.
class IconSelectScreen extends StatelessWidget {
  final String childId;

  const IconSelectScreen({required this.childId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アイコンを選ぶ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionCard(
              icon: Icons.photo_library_outlined,
              label: 'ギャラリーから選ぶ',
              onTap: () => _pickFromGallery(context),
            ),
            const SizedBox(height: 16),
            const _OptionCard(
              icon: Icons.draw_outlined,
              label: '手書きで描く',
              enabled: false,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final imageBytes = await ImagePickerChannel.pickImageFromGallery();
    if (imageBytes == null) return;
    if (!context.mounted) return;

    final croppedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageCropScreen(imageBytes: imageBytes),
      ),
    );

    if (croppedBytes == null) return;

    final filePath = await _savePng(croppedBytes);
    if (!context.mounted) return;

    Navigator.of(context).pop(filePath);
  }

  Future<String> _savePng(Uint8List bytes) async {
    final appDir = await getApplicationDocumentsDirectory();
    final iconsDir = Directory('${appDir.path}/icons');
    if (!await iconsDir.exists()) {
      await iconsDir.create(recursive: true);
    }
    final filePath = '${iconsDir.path}/$childId.png';
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Card(
      elevation: enabled ? 2 : 0,
      color: enabled
          ? null
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
                color: enabled ? theme.colorScheme.primary : disabledColor,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: enabled ? null : disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen crop UI with a fixed 1:1 aspect ratio.
class _ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const _ImageCropScreen({required this.imageBytes});

  @override
  State<_ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<_ImageCropScreen> {
  final _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('切り取り'),
        actions: [
          TextButton(
            onPressed: _cropController.crop,
            child: const Text('完了'),
          ),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _cropController,
        aspectRatio: 1.0,
        onCropped: (croppedImage) {
          Navigator.of(context).pop(croppedImage);
        },
      ),
    );
  }
}
