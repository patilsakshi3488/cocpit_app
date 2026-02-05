import 'package:flutter/material.dart';
import 'package:cocpit_app/views/story/editor/story_editor_screen.dart';

class StoryStateMapper {
  /// Converts metadata JSON back into a list of TextLayers.
  /// Requires [canvasSize] (usually screen size) to convert percentages back to pixels.
  static List<TextLayer> metadataToLayers(
    Map<String, dynamic> metadata,
    Size canvasSize,
  ) {
    final List<dynamic> layerData = metadata['layers'] ?? [];
    final List<TextLayer> layers = [];

    for (var data in layerData) {
      if (data['type'] != 'text') continue;

      final style = data['style'] ?? {};
      final Color color = _parseHexColor(style['color'] ?? "#FFFFFF");
      final Color? bgColor = style['backgroundColor'] != null
          ? _parseHexColor(style['backgroundColor'])
          : null;

      final String content = data['content'] ?? "";
      final double xPct = (data['x'] as num?)?.toDouble() ?? 50.0;
      final double yPct = (data['y'] as num?)?.toDouble() ?? 50.0;
      final double wPct = (data['width'] as num?)?.toDouble() ?? 50.0;

      // Convert Pct back to Pixels
      // x,y in metadata are CENTER points.
      // Offset in TextLayer is TOP-LEFT point.
      // We'll estimate the size or just center it since the editor allows dragging.
      final double width = (wPct / 100) * canvasSize.width;
      final double centerX = (xPct / 100) * canvasSize.width;
      final double centerY = (yPct / 100) * canvasSize.height;

      // Note: Measurement in the editor is dynamic. We provide a reasonable starting offset.
      final Offset position = Offset(
        centerX - (width / 2),
        centerY - 25, // Estimate height as ~50px
      );

      layers.add(
        TextLayer(
          id: data['id'] ?? DateTime.now().toString(),
          text: content,
          color: color,
          backgroundColor: bgColor,
          align: _parseTextAlign(style['textAlign']),
          position: position,
          rotation:
              ((data['rotation'] as num?)?.toDouble() ?? 0.0) * (3.14159 / 180),
          scale: (data['scale'] as num?)?.toDouble() ?? 1.0,
        ),
      );
    }

    return layers;
  }

  static Color _parseHexColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }

  static TextAlign _parseTextAlign(String? align) {
    switch (align?.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  static Color parseBackground(Map<String, dynamic> metadata) {
    final hex = metadata['background'];
    if (hex == null) return Colors.black;
    return _parseHexColor(hex);
  }
}
