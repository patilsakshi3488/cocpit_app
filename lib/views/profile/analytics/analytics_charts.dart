import 'package:flutter/material.dart';
import 'dart:math' as math;

class RadarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final List<double> targetValues;
  final Color primary;
  final Color textColor;

  RadarChartPainter({
    required this.labels,
    required this.values,
    required this.targetValues,
    required this.primary,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final angleStep = (2 * math.pi) / labels.length;

    final paintGrid = Paint()
      ..color = textColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke;

    // Draw background hexagons
    for (var i = 1; i <= 5; i++) {
      final r = radius * (i / 5);
      final path = Path();
      for (var j = 0; j < labels.length; j++) {
        final angle = j * angleStep - math.pi / 2;
        final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        if (j == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paintGrid);
    }

    // Draw axis lines
    for (var j = 0; j < labels.length; j++) {
      final angle = j * angleStep - math.pi / 2;
      canvas.drawLine(center, Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)), paintGrid);
      
      // Draw labels
      final labelRadius = radius + 25;
      final labelPos = Offset(center.dx + labelRadius * math.cos(angle), center.dy + labelRadius * math.sin(angle));
      
      final textPainter = TextPainter(
        text: TextSpan(text: labels[j], style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(canvas, Offset(labelPos.dx - textPainter.width / 2, labelPos.dy - textPainter.height / 2));
    }

    // Draw Target values (Dashed line)
    final targetPath = Path();
    final paintTarget = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var j = 0; j < labels.length; j++) {
      final angle = j * angleStep - math.pi / 2;
      final r = radius * targetValues[j];
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (j == 0) {
        targetPath.moveTo(point.dx, point.dy);
      } else {
        targetPath.lineTo(point.dx, point.dy);
      }
    }
    targetPath.close();
    _drawDashedPath(canvas, targetPath, paintTarget);

    // Draw User values
    final userPath = Path();
    for (var j = 0; j < labels.length; j++) {
      final angle = j * angleStep - math.pi / 2;
      final r = radius * values[j];
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (j == 0) {
        userPath.moveTo(point.dx, point.dy);
      } else {
        userPath.lineTo(point.dx, point.dy);
      }
    }
    userPath.close();

    final paintFill = Paint()..color = primary.withValues(alpha: 0.3)..style = PaintingStyle.fill;
    final paintBorder = Paint()..color = primary..style = PaintingStyle.stroke..strokeWidth = 2.5;

    canvas.drawPath(userPath, paintFill);
    canvas.drawPath(userPath, paintBorder);
    
    // Draw Legend points in chart? No, usually done in widget.
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return true;
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> interactions;
  final List<double> profileViews;
  final Color primary;
  final Color accent;
  final Color textColor;
  final int? selectedIndex;

  LineChartPainter({
    required this.interactions,
    required this.profileViews,
    required this.primary,
    required this.accent,
    required this.textColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = textColor.withValues(alpha: 0.1)..style = PaintingStyle.stroke;
    
    for (var i = 0; i < 5; i++) {
      double y = size.height - (size.height / 4 * i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (interactions.isEmpty || profileViews.isEmpty) return;

    final double stepX = size.width / (interactions.length - 1);
    const double maxY = 200.0;

    Offset getOffset(int index, double value) {
      return Offset(index * stepX, size.height - (value / maxY * size.height));
    }

    // Profile Views Path
    final pViewsPath = Path();
    final pViewsAreaPath = Path();
    pViewsAreaPath.moveTo(0, size.height);
    
    for (var i = 0; i < profileViews.length; i++) {
      final point = getOffset(i, profileViews[i]);
      if (i == 0) {
        pViewsPath.moveTo(point.dx, point.dy);
      } else {
        pViewsPath.lineTo(point.dx, point.dy);
      }
      pViewsAreaPath.lineTo(point.dx, point.dy);
    }
    pViewsAreaPath.lineTo(size.width, size.height);
    pViewsAreaPath.close();

    final paintAreaViews = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primary.withValues(alpha: 0.4), primary.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(pViewsAreaPath, paintAreaViews);
    canvas.drawPath(pViewsPath, Paint()..color = primary..style = PaintingStyle.stroke..strokeWidth = 3);

    // Interactions Path
    final interactionsPath = Path();
    final interactionsAreaPath = Path();
    interactionsAreaPath.moveTo(0, size.height);

    for (var i = 0; i < interactions.length; i++) {
      final point = getOffset(i, interactions[i]);
      if (i == 0) {
        interactionsPath.moveTo(point.dx, point.dy);
      } else {
        interactionsPath.lineTo(point.dx, point.dy);
      }
      interactionsAreaPath.lineTo(point.dx, point.dy);
    }
    interactionsAreaPath.lineTo(size.width, size.height);
    interactionsAreaPath.close();

    final paintAreaInteractions = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(interactionsAreaPath, paintAreaInteractions);
    canvas.drawPath(interactionsPath, Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 3);

    if (selectedIndex != null && selectedIndex! < interactions.length) {
      final x = selectedIndex! * stepX;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.white54..strokeWidth = 1);
      
      final p1 = getOffset(selectedIndex!, profileViews[selectedIndex!]);
      final p2 = getOffset(selectedIndex!, interactions[selectedIndex!]);
      
      canvas.drawCircle(p1, 6, Paint()..color = Colors.white);
      canvas.drawCircle(p1, 4, Paint()..color = primary);
      
      canvas.drawCircle(p2, 6, Paint()..color = Colors.white);
      canvas.drawCircle(p2, 4, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}
