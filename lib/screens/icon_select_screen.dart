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

const _kBase = Color(0xFFE8E0D5);
const _kTextDark = Color(0xFF4A3828);
const _kTextMid = Color(0xFF9E8A78);
const _kAccent = Color(0xFF8B7355);

/// S04: Icon selection screen.
class IconSelectScreen extends StatelessWidget {
  final String childId;

  const IconSelectScreen({required this.childId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBase,
      appBar: NeumorphicAppBar(
        title: const Text('アイコンを選ぶ'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionCard(
              icon: Icons.photo_library_outlined,
              label: 'ギャラリーから選ぶ',
              description: '写真ライブラリから画像を選択します',
              onTap: () => _pickFromGallery(context),
            ),
            const SizedBox(height: 20),
            _OptionCard(
              icon: Icons.draw_outlined,
              label: '手書きで描く',
              description: '指で自由に絵を描いてアイコンにします',
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

    // Evict the old cached image so the updated file is reloaded on next display.
    imageCache.evict(FileImage(File(filePath)));

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
  final String description;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onPressed: onTap,
      style: NeumorphicStyle(
        depth: 6,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Row(
        children: [
          Neumorphic(
            style: NeumorphicStyle(
              depth: 4,
              boxShape: NeumorphicBoxShape.circle(),
              color: _kAccent.withValues(alpha: 0.15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, size: 32, color: _kAccent),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kTextMid,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _kTextMid),
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
    return Scaffold(
      backgroundColor: _kBase,
      appBar: NeumorphicAppBar(
        title: const Text('切り取り'),
        actions: [
          NeumorphicButton(
            onPressed: _cropController.crop,
            style: NeumorphicStyle(
              depth: 4,
              color: _kAccent,
              boxShape: NeumorphicBoxShape.roundRect(
                BorderRadius.circular(10),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '完了',
              style: TextStyle(
                color: Colors.white,
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
