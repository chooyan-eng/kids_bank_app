import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:path_provider/path_provider.dart';

import '../models/child.dart';
import '../services/image_picker_channel.dart';
import 'drawing_canvas_screen.dart';

/// Result returned by [IconSelectScreen] to the caller.
typedef IconSelectResult = ({String path, IconType iconType});

/// S04: Icon selection screen.
/// Shown when the user taps the avatar in [ChildEditScreen].
///
/// [childId] is used to derive the save path for the icon image.
/// Returns [IconSelectResult] via Navigator.pop, or null if cancelled.
class IconSelectScreen extends StatelessWidget {
  final String childId;

  const IconSelectScreen({required this.childId, super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = NeumorphicTheme.baseColor(context);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: NeumorphicAppBar(
        title: const Text(
          'アイコンを選ぶ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF3D3D3D),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionCard(
              icon: Icons.photo_library_outlined,
              label: 'ギャラリーから選ぶ',
              onTap: () => _pickFromGallery(context),
            ),
            const SizedBox(height: 20),
            _OptionCard(
              icon: Icons.draw_outlined,
              label: '手書きで描く',
              onTap: () => _drawIcon(context),
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

    Navigator.of(context)
        .pop((path: filePath, iconType: IconType.gallery) as IconSelectResult);
  }

  Future<void> _drawIcon(BuildContext context) async {
    final filePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => DrawingCanvasScreen(childId: childId),
      ),
    );

    if (filePath == null) return;
    if (!context.mounted) return;

    Navigator.of(context)
        .pop((path: filePath, iconType: IconType.drawing) as IconSelectResult);
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
    return NeumorphicButton(
      style: NeumorphicStyle(
        depth: enabled ? 6 : 2,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(22)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      onPressed: onTap,
      child: Row(
        children: [
          Neumorphic(
            style: NeumorphicStyle(
              depth: enabled ? 4 : 1,
              color: enabled ? const Color(0xFFFFE0B2) : null,
              boxShape: NeumorphicBoxShape.circle(),
            ),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: Icon(
                  icon,
                  size: 30,
                  color: enabled
                      ? const Color(0xFFE65100)
                      : const Color(0xFF8E8E8E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color:
                  enabled ? const Color(0xFF3D3D3D) : const Color(0xFF8E8E8E),
            ),
          ),
        ],
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
    final baseColor = NeumorphicTheme.baseColor(context);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: NeumorphicAppBar(
        title: const Text(
          '切り取り',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF3D3D3D),
          ),
        ),
        actions: [
          NeumorphicButton(
            style: NeumorphicStyle(
              depth: 4,
              color: const Color(0xFFFFB74D),
              boxShape:
                  NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: _cropController.crop,
            child: const Text(
              '完了',
              style: TextStyle(
                color: Color(0xFF7B4F00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _cropController,
        aspectRatio: 1.0,
        onCropped: (result) {
          if (result is CropSuccess) {
            Navigator.of(context).pop(result.croppedImage);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
