import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class StoryCropScreen extends StatefulWidget {
  final File imageFile;

  // Initial values passed from the editor
  final double initialRotation;
  final double initialScale;
  final Offset initialPosition;

  const StoryCropScreen({
    super.key,
    required this.imageFile,
    this.initialRotation = 0.0,
    this.initialScale = 1.0,
    this.initialPosition = Offset.zero,
  });

  @override
  State<StoryCropScreen> createState() => _StoryCropScreenState();
}

class _StoryCropScreenState extends State<StoryCropScreen> {
  late double _rotation;
  late double _scale;

  @override
  void initState() {
    super.initState();
    _rotation = widget.initialRotation;
    _scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Canvas Area
            Expanded(
              child: ClipRect(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateZ(_rotation)
                        ..scale(_scale, _scale, 1.0),
                      child: Image.file(widget.imageFile, fit: BoxFit.contain),
                    ),

                    // Grid Overlay (Rule of Thirds)
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: GridPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ratios
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRatioButton("Free", null),
                          _buildRatioButton("9:16", 9 / 16),
                          _buildRatioButton("16:9", 16 / 9),
                          _buildRatioButton("4:5", 4 / 5),
                          _buildRatioButton("1:1", 1 / 1),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Zoom Slider
                    Row(
                      children: [
                        const Text(
                          "Zoom",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Expanded(
                          child: Slider(
                            value: _scale,
                            min: 0.5,
                            max: 3.0,
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey,
                            onChanged: (v) => setState(() => _scale = v),
                          ),
                        ),
                      ],
                    ),

                    // Rotate Slider
                    Row(
                      children: [
                        const Text(
                          "Rotate",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Expanded(
                          child: Slider(
                            value: _rotation,
                            min: -math.pi,
                            max: math.pi,
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey,
                            onChanged: (v) => setState(() => _rotation = v),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'rotation': _rotation,
                              'scale': _scale,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text("Apply Crop"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioButton(String label, double? ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: false, // Visual only for now
        backgroundColor: Colors.grey[900],
        selectedColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        onSelected: (_) {
          // TODO: Implement Mask Application
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aspect Ratio masking coming soon"),
              duration: Duration(milliseconds: 500),
            ),
          );
        },
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Horizontals
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );

    // Verticals
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
