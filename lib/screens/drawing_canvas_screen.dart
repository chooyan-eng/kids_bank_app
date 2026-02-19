import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

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

  // Undo stack: each entry is a snapshot of _strokes before an action.
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
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final filePath = await _savePng(bytes);

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
    final baseColor = NeumorphicTheme.baseColor(context);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: NeumorphicAppBar(
        title: const Text(
          '手書きアイコン',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF3D3D3D),
          ),
        ),
        actions: [
          NeumorphicButton(
            style: const NeumorphicStyle(
              boxShape: NeumorphicBoxShape.circle(),
              depth: 3,
            ),
            padding: const EdgeInsets.all(8),
            onPressed: _undoStack.isEmpty ? null : _undo,
            child: Icon(
              Icons.undo,
              size: 22,
              color: _undoStack.isEmpty
                  ? const Color(0xFFBDBDBD)
                  : const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(width: 6),
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF7B4F00),
                      ),
                    ),
                  ),
                )
              : NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 4,
                    color: const Color(0xFFFFB74D),
                    boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(10)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: _complete,
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
      body: Column(
        children: [
          // Square canvas that fills the available width
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Neumorphic(
                  style: NeumorphicStyle(
                    depth: -4,
                    boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(16)),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
          SafeArea(
            top: false,
            child: Neumorphic(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              style: NeumorphicStyle(
                depth: 4,
                boxShape: NeumorphicBoxShape.roundRect(
                    BorderRadius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Color swatches
                    for (final color in _colors)
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedColor = color;
                          _isEraserMode = false;
                        }),
                        child: Neumorphic(
                          margin: const EdgeInsets.only(right: 8),
                          style: NeumorphicStyle(
                            depth: !_isEraserMode && _selectedColor == color
                                ? -3
                                : 3,
                            color: color == Colors.yellow
                                ? Colors.yellow
                                : color == Colors.black
                                    ? const Color(0xFF212121)
                                    : color == Colors.red
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFF1565C0),
                            boxShape: NeumorphicBoxShape.circle(),
                          ),
                          child: const SizedBox(width: 30, height: 30),
                        ),
                      ),

                    const Spacer(),

                    // Pen width toggles
                    for (final width in _widths)
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedWidth = width;
                          _isEraserMode = false;
                        }),
                        child: Neumorphic(
                          margin: const EdgeInsets.only(right: 8),
                          style: NeumorphicStyle(
                            depth: _selectedWidth == width && !_isEraserMode
                                ? -3
                                : 3,
                            boxShape: NeumorphicBoxShape.circle(),
                          ),
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Center(
                              child: Container(
                                width: width,
                                height: width,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3D3D3D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Eraser toggle
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isEraserMode = !_isEraserMode),
                      child: Neumorphic(
                        style: NeumorphicStyle(
                          depth: _isEraserMode ? -3 : 3,
                          color: _isEraserMode
                              ? const Color(0xFFFFE0B2)
                              : null,
                          boxShape: NeumorphicBoxShape.circle(),
                        ),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Center(
                            child: Icon(
                              Icons.cleaning_services_outlined,
                              size: 18,
                              color: _isEraserMode
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF5D5D5D),
                            ),
                          ),
                        ),
                      ),
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
