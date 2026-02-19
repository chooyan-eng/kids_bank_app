import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:draw_your_image/draw_your_image.dart';
import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('手書きアイコン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoStack.isEmpty ? null : _undo,
            tooltip: '元に戻す',
          ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _complete,
                  child: const Text('完了'),
                ),
        ],
      ),
      body: Column(
        children: [
          // Square canvas that fills the available width
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
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
          const Divider(height: 1),
          // Toolbar
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Color swatches
                  for (final color in _colors)
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedColor = color;
                        _isEraserMode = false;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: !_isEraserMode && _selectedColor == color
                                ? theme.colorScheme.primary
                                : Colors.grey.shade300,
                            width:
                                !_isEraserMode && _selectedColor == color
                                    ? 3
                                    : 1,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Pen width toggles
                  for (final width in _widths)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedWidth = width),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedWidth == width
                                ? theme.colorScheme.primary
                                : Colors.grey.shade300,
                            width: _selectedWidth == width ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: width,
                          height: width,
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  // Eraser toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isEraserMode = !_isEraserMode),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isEraserMode
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                          width: _isEraserMode ? 2 : 1,
                        ),
                        color: _isEraserMode
                            ? theme.colorScheme.primaryContainer
                            : null,
                      ),
                      child: Icon(
                        Icons.cleaning_services_outlined,
                        size: 20,
                        color: _isEraserMode
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
