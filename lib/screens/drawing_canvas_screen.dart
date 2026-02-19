import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

const _kBase = Color(0xFFE8E0D5);
const _kTextDark = Color(0xFF4A3828);
const _kTextMid = Color(0xFF9E8A78);
const _kAccent = Color(0xFF8B7355);

/// S05: Drawing canvas screen.
///
/// Lets the user draw a freehand icon using a finger or stylus.
/// [childId] determines the save path for the resulting PNG file.
/// Returns the saved file path (String) via Navigator.pop, or null if cancelled.
class DrawingCanvasScreen extends StatefulWidget {
  final String childId;

  const DrawingCanvasScreen({required this.childId, super.key});

  @override
  State<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  List<Stroke> _strokes = [];
  final List<List<Stroke>> _undoStack = [];

  Color _selectedColor = Colors.black;
  double _selectedWidth = 5.0;
  bool _isEraserMode = false;
  bool _isSaving = false;

  final GlobalKey _repaintKey = GlobalKey();

  static const _colors = [Colors.black, Colors.red, Colors.blue, Colors.yellow];
  static const _widths = [2.0, 5.0, 10.0];

  void _onStrokeDrawn(Stroke stroke) {
    setState(() {
      _undoStack.add(List.from(_strokes));
      _strokes = [..._strokes, stroke];
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _strokes = _undoStack.removeLast();
    });
  }

  Future<void> _complete() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final filePath = await _savePng(bytes);

      // Evict the old cached image so the updated file is reloaded on next display.
      imageCache.evict(FileImage(File(filePath)));

      if (mounted) Navigator.of(context).pop(filePath);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String> _savePng(Uint8List bytes) async {
    final appDir = await getApplicationDocumentsDirectory();
    final iconsDir = Directory('${appDir.path}/icons');
    if (!await iconsDir.exists()) {
      await iconsDir.create(recursive: true);
    }
    final filePath = '${iconsDir.path}/${widget.childId}.png';
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBase,
      appBar: NeumorphicAppBar(
        title: const Text('手書きアイコン'),
        actions: [
          NeumorphicButton(
            onPressed: _undoStack.isEmpty ? null : _undo,
            style: NeumorphicStyle(
              boxShape: NeumorphicBoxShape.circle(),
              depth: _undoStack.isEmpty ? 1 : 4,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.undo,
              size: 20,
              color: _undoStack.isEmpty ? _kTextMid : _kTextDark,
            ),
          ),
          const SizedBox(width: 8),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kAccent,
                    ),
                  ),
                )
              : NeumorphicButton(
                  onPressed: _complete,
                  style: NeumorphicStyle(
                    depth: 4,
                    color: _kAccent,
                    boxShape: NeumorphicBoxShape.roundRect(
                      BorderRadius.circular(10),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
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
      body: Column(
        children: [
          // Square canvas
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Neumorphic(
                    style: NeumorphicStyle(
                      depth: -6,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(20),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: Draw(
                          strokes: _strokes,
                          strokeColor: _selectedColor,
                          strokeWidth: _selectedWidth,
                          backgroundColor: Colors.white,
                          onStrokeStarted: (newStroke, currentStroke) {
                            return currentStroke ??
                                newStroke.copyWith(
                                  data: {#erasing: _isEraserMode},
                                );
                          },
                          onStrokeDrawn: _onStrokeDrawn,
                          strokePainter: (stroke) {
                            if (stroke.data?[#erasing] == true) {
                              return [eraseWithDefault(stroke)];
                            }
                            return [paintWithDefault(stroke)];
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Toolbar
          Neumorphic(
            style: NeumorphicStyle(
              depth: 4,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.zero),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Color swatches
                    for (final color in _colors)
                      _ColorSwatch(
                        color: color,
                        isSelected: !_isEraserMode && _selectedColor == color,
                        onTap: () => setState(() {
                          _selectedColor = color;
                          _isEraserMode = false;
                        }),
                      ),
                    const Spacer(),
                    // Pen width toggles
                    for (final width in _widths)
                      _WidthToggle(
                        width: width,
                        isSelected: !_isEraserMode && _selectedWidth == width,
                        onTap: () => setState(() {
                          _selectedWidth = width;
                          _isEraserMode = false;
                        }),
                      ),
                    const SizedBox(width: 4),
                    // Eraser toggle
                    _EraserButton(
                      isActive: _isEraserMode,
                      onTap: () =>
                          setState(() => _isEraserMode = !_isEraserMode),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Neumorphic(
        margin: const EdgeInsets.only(right: 10),
        style: NeumorphicStyle(
          depth: isSelected ? -4 : 3,
          boxShape: NeumorphicBoxShape.circle(),
          color: color,
        ),
        child: SizedBox(
          width: 34,
          height: 34,
          child: isSelected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _WidthToggle extends StatelessWidget {
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  const _WidthToggle({
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Neumorphic(
        margin: const EdgeInsets.only(right: 8),
        style: NeumorphicStyle(
          depth: isSelected ? -4 : 3,
          boxShape: NeumorphicBoxShape.circle(),
          color: isSelected
              ? const Color(0xFF8B7355).withValues(alpha: 0.2)
              : null,
        ),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                color: isSelected ? _kAccent : Colors.black87,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EraserButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _EraserButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: isActive ? -4 : 3,
          boxShape: NeumorphicBoxShape.circle(),
          color: isActive
              ? const Color(0xFF8B7355).withValues(alpha: 0.2)
              : null,
        ),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(
              Icons.cleaning_services_outlined,
              size: 20,
              color: isActive ? _kAccent : _kTextMid,
            ),
          ),
        ),
      ),
    );
  }
}
