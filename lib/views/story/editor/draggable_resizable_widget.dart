import 'dart:math' as math;
import 'package:flutter/material.dart';

class DraggableResizableWidget extends StatefulWidget {
  final Widget child;
  final Function(Offset, double, double)? onUpdate;
  final Function(bool)?
  onDragStart; // To notify parent about dragging (for delete zone)
  final Function(Offset)? onDragEnd; // To check if dropped in trash
  final VoidCallback? onTap;

  // Initial stats
  final Offset initialPosition;
  final double initialRotation;
  final double initialScale;

  const DraggableResizableWidget({
    super.key,
    required this.child,
    this.onUpdate,
    this.onDragStart,
    this.onDragEnd,
    this.onTap,
    this.initialPosition = Offset.zero,
    this.initialRotation = 0.0,
    this.initialScale = 1.0,
  });

  @override
  State<DraggableResizableWidget> createState() =>
      _DraggableResizableWidgetState();
}

class _DraggableResizableWidgetState extends State<DraggableResizableWidget> {
  late Offset _position;
  late double _rotation;
  late double _scale;

  // Gesture state
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _rotation = widget.initialRotation;
    _scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    // We use a Stack-friendly implementation. Ideally this widget is placed inside a Stack.
    // The Positioned widget controls its location.

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onScaleStart: (details) {
          _baseScale = _scale;
          _baseRotation = _rotation;
          _basePosition = _position;

          if (widget.onDragStart != null) {
            widget.onDragStart!(true);
          }
        },
        onScaleUpdate: (details) {
          // Basic Implementation for standard "Sticker" feel:
          // 1. Translation: Move based on focal point delta
          // 2. Scale: Multiply base
          // 3. Rotation: Add delta

          setState(() {
            _position += details.focalPointDelta;
            _scale = math.max(
              0.3,
              _baseScale * details.scale,
            ); // Min scale limit
            _rotation = _baseRotation + details.rotation;
          });

          if (widget.onUpdate != null) {
            widget.onUpdate!(_position, _rotation, _scale);
          }
        },
        onScaleEnd: (details) {
          if (widget.onDragStart != null) {
            widget.onDragStart!(false);
          }
          if (widget.onDragEnd != null) {
            // Pass the center of the widget (approx) or the touch point?
            // Position is the top-left corner usually in a Positioned.
            // We pass current position for hit testing against delete zone.
            widget.onDragEnd!(_position);
          }
        },
        child: Transform(
          transform: Matrix4.identity()
            ..rotateZ(_rotation)
            ..scale(_scale),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
