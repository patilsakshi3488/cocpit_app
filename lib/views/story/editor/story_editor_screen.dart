import 'dart:io';
import 'package:cocpit_app/views/story/editor/background_picker_sheet.dart';
import 'package:cocpit_app/views/story/editor/draggable_resizable_widget.dart';
import 'package:cocpit_app/views/story/editor/story_crop_screen.dart';
import 'package:cocpit_app/views/story/preview/story_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:video_player/video_player.dart';

class StoryEditorScreen extends StatefulWidget {
  final File? initialFile;
  final bool isVideo;
  final Color? initialBackgroundColor;
  final List<TextLayer>? initialTextLayers;

  const StoryEditorScreen({
    super.key,
    this.initialFile, // Nullable now
    required this.isVideo,
    this.initialBackgroundColor,
    this.initialTextLayers,
  });

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  // State for layers
  final ScreenshotController _screenshotController = ScreenshotController();
  VideoPlayerController? _videoController;

  // Crop / Transform state
  double _rotation = 0.0;
  double _scale = 1.0;

  // Background state
  Color _backgroundColor = Colors.black;
  LinearGradient? _backgroundGradient;

  // Text layers
  final List<TextLayer> _textLayers = [];

  // Undo Stack
  final List<EditorState> _undoStack = [];

  // Active Tool
  final StoryEditorTool _activeTool = StoryEditorTool.none;

  // Canvas Key for metadata calculation
  final GlobalKey _canvasKey = GlobalKey();
  final bool _hideTextForCapture = false;

  // Deletion State
  bool _isDragging = false;
  bool _isOverDeleteZone = false;

  // --- Inline Text Editor State ---
  bool _isTextEditing = false;
  final TextEditingController _textController = TextEditingController();
  TextLayer? _editingLayer; // If null, we are creating new text
  Color _textColor = Colors.white;
  Color? _textBackgroundColor;
  TextAlign _textAlign = TextAlign.center;

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    // Initialize background if provided
    if (widget.initialBackgroundColor != null) {
      _backgroundColor = widget.initialBackgroundColor!;
    }

    // Initialize text layers if provided (copy copies to avoid mutation of original list if externally held)
    if (widget.initialTextLayers != null) {
      _textLayers.addAll(widget.initialTextLayers!.map((e) => e.copy()));
    }

    if (widget.isVideo && widget.initialFile != null) {
      _videoController = VideoPlayerController.file(widget.initialFile!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.play();
            _videoController!.setLooping(true);
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When editing text, we might want to hide the bottom toolbar or other elements
    // but KEEP the image visible.

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Handle in stack
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Bar (Hidden when text editing)
                if (!_isDragging && !_isTextEditing) _buildTopBar(),

                // Main Canvas
                Expanded(
                  child: ClipRect(
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        key: _canvasKey,
                        decoration: BoxDecoration(
                          color: _backgroundGradient == null
                              ? _backgroundColor
                              : null,
                          gradient: _backgroundGradient,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          fit: StackFit.expand,
                          children: [
                            // Base Layer (Image OR Video OR Just Background)
                            if (widget.initialFile != null)
                              widget.isVideo
                                  ? (_videoController != null &&
                                            _videoController!
                                                .value
                                                .isInitialized
                                        ? FittedBox(
                                            fit: BoxFit.contain,
                                            child: SizedBox(
                                              width: _videoController!
                                                  .value
                                                  .size
                                                  .width,
                                              height: _videoController!
                                                  .value
                                                  .size
                                                  .height,
                                              child: VideoPlayer(
                                                _videoController!,
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: CircularProgressIndicator(),
                                          ))
                                  : Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..rotateZ(_rotation)
                                        ..scale(_scale, _scale, 1.0),
                                      child: Image.file(
                                        widget.initialFile!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                            // Note: If initialFile is null, the Container's color/gradient acts as the background.

                            // Text Layers (Rendered when NOT editing them specifically)
                            ..._textLayers.map((layer) {
                              // If we are editing THIS layer, hide it from the stack so we don't see double
                              if ((_isTextEditing && _editingLayer == layer) ||
                                  _hideTextForCapture) {
                                return const SizedBox.shrink();
                              }
                              return DraggableResizableWidget(
                                key: ValueKey(layer.id),
                                initialPosition: layer.position,
                                initialRotation: layer.rotation,
                                initialScale: layer.scale,
                                onDragStart: (dragging) {
                                  if (_isTextEditing) return;
                                  setState(() {
                                    _isDragging = dragging;
                                  });
                                },
                                onUpdate: (pos, rot, scale) {
                                  if (_isTextEditing) return;
                                  layer.position = pos;
                                  layer.rotation = rot;
                                  layer.scale = scale;
                                  _checkDeleteZone(pos);
                                },
                                onDragEnd: (finalPos) {
                                  if (_isTextEditing) return;
                                  setState(() {
                                    _isDragging = false;
                                    _isOverDeleteZone = false;
                                  });
                                  if (finalPos.dy >
                                      MediaQuery.of(context).size.height *
                                          0.70) {
                                    _deleteLayer(layer);
                                  }
                                },
                                onTap: () => _startTextEditing(layer),
                                child: _buildTextLayerWidget(layer),
                              );
                            }),

                            // Delete Zone
                            if (_isDragging) _buildDeleteZone(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Toolbar (Hidden when text editing)
                if (!_isDragging && !_isTextEditing) _buildBottomToolbar(),
              ],
            ),

            // --- INLINE TEXT EDITOR OVERLAY ---
            if (_isTextEditing) _buildTextEditorOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextLayerWidget(TextLayer layer) {
    return Container(
      key: layer.key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: layer.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        layer.text,
        textAlign: layer.align,
        style: TextStyle(
          fontSize: 32,
          color: layer.color,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget _buildDeleteZone() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isOverDeleteZone
              ? Colors.red.withValues(alpha: 0.8)
              : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: _isOverDeleteZone ? 36 : 28,
        ),
      ),
    );
  }

  // --- Editor Overlay UI ---

  Widget _buildTextEditorOverlay() {
    return Container(
      color: Colors.black.withValues(
        alpha: 0.4,
      ), // Minimal dimming to focus text
      child: Column(
        children: [
          // Editor Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _textAlign == TextAlign.left
                            ? Icons.format_align_left
                            : _textAlign == TextAlign.right
                            ? Icons.format_align_right
                            : Icons.format_align_center,
                        color: Colors.white,
                      ),
                      onPressed: _toggleTextAlign,
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "A",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textBackgroundColor == null
                                ? Colors.white
                                : (_textBackgroundColor == Colors.white
                                      ? Colors.black
                                      : Colors.white),
                          ),
                        ),
                      ),
                      onPressed: _toggleTextBackground,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _finishTextEditing,
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Text Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicWidth(
              child: TextField(
                controller: _textController,
                autofocus: true,
                textAlign: _textAlign,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 32,
                  color: _textColor,
                  backgroundColor: _textBackgroundColor,
                ),
                maxLines: null,
                decoration: const InputDecoration(border: InputBorder.none),
                cursorColor: Colors.white,
              ),
            ),
          ),

          const Spacer(),

          // Color Picker
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                return GestureDetector(
                  onTap: () => setState(() => _textColor = color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _textColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Handle Keyboard Spacer
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  // --- Logic Helpers ---

  void _checkDeleteZone(Offset pos) {
    if (pos.dy > MediaQuery.of(context).size.height * 0.70) {
      if (!_isOverDeleteZone) setState(() => _isOverDeleteZone = true);
    } else {
      if (_isOverDeleteZone) setState(() => _isOverDeleteZone = false);
    }
  }

  void _deleteLayer(TextLayer layer) {
    _saveStateForUndo();
    setState(() {
      _textLayers.removeWhere((l) => l.id == layer.id);
    });
  }

  // --- Text Editor Logic ---

  void _startTextEditing(TextLayer? layer) {
    setState(() {
      _isTextEditing = true;
      _editingLayer = layer;

      if (layer != null) {
        // Fix: Clear placeholder text
        if (layer.text == "\"Your Quote Here\"" || layer.text == "BIG NEWS") {
          _textController.text = "";
        } else {
          _textController.text = layer.text;
        }
        _textColor = layer.color;
        _textBackgroundColor = layer.backgroundColor;
        _textAlign = layer.align;
      } else {
        _textController.text = "";
        _textColor = Colors.white;
        _textBackgroundColor = null;
        _textAlign = TextAlign.center;
      }
    });
  }

  void _finishTextEditing() {
    if (_textController.text.trim().isNotEmpty) {
      _saveStateForUndo();
      setState(() {
        if (_editingLayer != null) {
          // Update existing
          _editingLayer!.text = _textController.text;
          _editingLayer!.color = _textColor;
          _editingLayer!.backgroundColor = _textBackgroundColor;
          _editingLayer!.align = _textAlign;
        } else {
          // Create new
          final center = Offset(
            MediaQuery.of(context).size.width / 2 - 50,
            MediaQuery.of(context).size.height / 2 - 20,
          );
          _textLayers.add(
            TextLayer(
              id: DateTime.now().toString(),
              text: _textController.text,
              color: _textColor,
              backgroundColor: _textBackgroundColor,
              align: _textAlign,
              position: center,
            ),
          );
        }
      });
    }

    // Cleanup
    setState(() {
      _isTextEditing = false;
      _editingLayer = null;
      _textController.clear();
    });
  }

  void _toggleTextAlign() {
    setState(() {
      if (_textAlign == TextAlign.left) {
        _textAlign = TextAlign.center;
      } else if (_textAlign == TextAlign.center) {
        _textAlign = TextAlign.right;
      } else {
        _textAlign = TextAlign.left;
      }
    });
  }

  void _toggleTextBackground() {
    setState(() {
      if (_textBackgroundColor == null) {
        _textBackgroundColor = Colors.black45;
      } else if (_textBackgroundColor == Colors.black45) {
        _textBackgroundColor = _textColor == Colors.white
            ? Colors.black
            : Colors.white;
      } else {
        _textBackgroundColor = null;
      }
    });
  }

  // --- Toolbar & Action Logic ---

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          if (_undoStack.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white),
              onPressed: _undo,
            )
          else
            const SizedBox(width: 48),

          ElevatedButton(
            onPressed: _exportImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
            ),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Crop is disabled for Video OR Text-only stories (no base image)
          _buildToolItem(
            Icons.crop,
            "Crop",
            StoryEditorTool.crop,
            disabled: widget.isVideo || widget.initialFile == null,
          ),
          _buildToolItem(Icons.text_fields, "Text", StoryEditorTool.text),
          _buildToolItem(
            Icons.emoji_emotions_outlined,
            "Sticker",
            StoryEditorTool.sticker,
          ),
          _buildToolItem(
            Icons.palette_outlined,
            "Background",
            StoryEditorTool.background,
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(
    IconData icon,
    String label,
    StoryEditorTool tool, {
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : () => _handleToolSelection(tool),
      child: Opacity(
        opacity: disabled ? 0.3 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[900],
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToolSelection(StoryEditorTool tool) async {
    switch (tool) {
      case StoryEditorTool.crop:
        if (widget.isVideo || widget.initialFile == null) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryCropScreen(
              imageFile: widget.initialFile!,
              initialRotation: _rotation,
              initialScale: _scale,
            ),
          ),
        );
        if (result != null && result is Map) {
          _saveStateForUndo();
          setState(() {
            _rotation = result['rotation'];
            _scale = result['scale'];
          });
        }
        break;

      case StoryEditorTool.text:
        _startTextEditing(null);
        break;

      case StoryEditorTool.background:
        _saveStateForUndo();
        final result = await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => const BackgroundPickerSheet(),
        );
        if (result != null) {
          setState(() {
            if (result is Color) {
              _backgroundColor = result;
              _backgroundGradient = null;
            } else if (result is LinearGradient) {
              _backgroundGradient = result;
            }
          });
        }
        break;

      case StoryEditorTool.sticker:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Stickers coming soon!")));
        break;

      case StoryEditorTool.none:
        break;
    }
  }

  void _saveStateForUndo() {
    _undoStack.add(
      EditorState(
        rotation: _rotation,
        scale: _scale,
        backgroundColor: _backgroundColor,
        backgroundGradient: _backgroundGradient,
        textLayers: _textLayers.map((e) => e.copy()).toList(),
      ),
    );
    setState(() {});
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final lastState = _undoStack.removeLast();
    setState(() {
      _rotation = lastState.rotation;
      _scale = lastState.scale;
      _backgroundColor = lastState.backgroundColor;
      _backgroundGradient = lastState.backgroundGradient;
      _textLayers.clear();
      _textLayers.addAll(lastState.textLayers);
    });
  }

  Future<void> _exportImage() async {
    try {
      // 1. Generate Metadata (Always good for future re-edits or app logic)
      final metadata = await _generateMetadata();

      final uploadFile = widget.initialFile;
      if (uploadFile == null) return;

      // Navigate to Preview with Metadata + Raw State for Re-edit
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryPreviewScreen(
              storyFile: uploadFile,
              isVideo: widget.isVideo,
              storyMetadata: metadata,
              originalLayers: _textLayers, // âœ… Passed for Re-edit
              originalBackgroundColor:
                  _backgroundColor, // âœ… Passed for Re-edit
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Export error: $e");
    }
  }

  Future<Map<String, dynamic>> _generateMetadata() async {
    // Measure Canvas
    final RenderBox? canvasBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final Size canvasSize = canvasBox?.size ?? MediaQuery.of(context).size;

    final layers = <Map<String, dynamic>>[];

    // 1. Add Main Media Layer (if exists)
    if (widget.initialFile != null) {
      layers.add({
        "id": "main-image", // or main-video
        "type": widget.isVideo ? "video" : "image",
        "x": 50.0,
        "y": 50.0,
        "width": 100.0,
        "height": 100.0,
        "rotation": _rotation * (180 / 3.14159), // Convert Rad to Deg
        "scale": _scale,
        "zIndex": 0,
      });
    }

    // 2. Add Text Layers
    for (var i = 0; i < _textLayers.length; i++) {
      final layer = _textLayers[i];
      final RenderBox? box =
          layer.key.currentContext?.findRenderObject() as RenderBox?;

      // Default to estimated size if measurement fails (fallback)
      final Size size = box?.size ?? const Size(200, 50);

      // Calculate Center Position %
      final centerX = layer.position.dx + (size.width / 2);
      final centerY = layer.position.dy + (size.height / 2);

      final xPct = (centerX / canvasSize.width) * 100;
      final yPct = (centerY / canvasSize.height) * 100;
      final wPct = (size.width / canvasSize.width) * 100;

      layers.add({
        "id": layer.id,
        "type": "text",
        "content": layer.text,
        "x": xPct,
        "y": yPct,
        "width": wPct,
        "height": 0.0, // Text auto-height
        "rotation": layer.rotation * (180 / 3.14159),
        "scale": layer.scale,
        "zIndex": 10 + i,
        "style": {
          "color":
              "#${layer.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}", // ARGB -> RGB(maybe with alpha?)
          // Website uses hex code usually. substring(2) keeps RRGGBB
          // But flutter color value is AARRGGBB.
          // If alpha is involved, web hex usually handles it or uses rgba.
          // Simplest: use RRGGBB if alpha 255.
          // Let's use generic helper or just RRGGBB for now.
          "textAlign": layer.align.toString().split('.').last,
          "fontSize": 32,
          "fontWeight": "bold",
          "fontFamily": "Roboto",
        },
      });
    }

    return {
      "version": "1.0",
      "layers": layers,
      if (_backgroundColor != Colors.black)
        "background":
            "#${_backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}",
    };
  }
}

enum StoryEditorTool { none, crop, text, sticker, background }

class EditorState {
  final double rotation;
  final double scale;
  final Color backgroundColor;
  final LinearGradient? backgroundGradient;
  final List<TextLayer> textLayers;

  EditorState({
    required this.rotation,
    required this.scale,
    required this.backgroundColor,
    this.backgroundGradient,
    required this.textLayers,
  });
}

class TextLayer {
  String id;
  String text;
  Color color;
  Color? backgroundColor;
  TextAlign align;
  Offset position;
  double rotation;
  double scale;
  GlobalKey key = GlobalKey(); // NEW: For measurement

  TextLayer({
    required this.id,
    required this.text,
    required this.color,
    this.backgroundColor,
    required this.align,
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
    GlobalKey? key,
  }) {
    if (key != null) this.key = key;
  }

  TextLayer copy() {
    return TextLayer(
      id: id,
      text: text,
      color: color,
      backgroundColor: backgroundColor,
      align: align,
      position: position,
      rotation: rotation,
      scale: scale,
      key: GlobalKey(), // New key for the copy
    );
  }
}
