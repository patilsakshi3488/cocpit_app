import 'dart:math';
import 'package:flutter/material.dart';

class PollAnalyticsDialog extends StatefulWidget {
  final List<dynamic> options;

  const PollAnalyticsDialog({super.key, required this.options});

  @override
  State<PollAnalyticsDialog> createState() => _PollAnalyticsDialogState();
}

class _PollAnalyticsDialogState extends State<PollAnalyticsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _totalVotes = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    for (var o in widget.options) {
      _totalVotes += _asInt(o["vote_count"]);
    }

    _controller.forward();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.canvasColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Poll Results",
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Chart Section
              SizedBox(
                height: 180,
                width: 180,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _PieChartPainter(
                        options: widget.options,
                        totalVotes: _totalVotes,
                        progress: _animation.value,
                        bgColor: theme.dividerColor.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$_totalVotes",
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            Text(
                              "Votes",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // List Section with stats bars
              ...List.generate(widget.options.length, (index) {
                final o = widget.options[index];
                final count = _asInt(o["vote_count"]);
                double percentage = _totalVotes > 0
                    ? (count / _totalVotes)
                    : 0.0;

                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final animatedPercent = percentage * _animation.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  o["option_text"] ?? "",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${(percentage * 100).toStringAsFixed(0)}%",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: animatedPercent,
                              backgroundColor: theme.dividerColor.withOpacity(
                                0.1,
                              ),
                              color: _getColor(index),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$count votes",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: theme.hintColor,
            ),
            child: const Text("Close"),
          ),
        ),
      ],
    );
  }
}

Color _getColor(int index) {
  const colors = [
    Color(0xFF6B72FF),
    Color(0xFFFF70A6),
    Color(0xFFFF9770),
    Color(0xFFFFD670),
    Color(0xFFE9FF70),
  ];
  return colors[index % colors.length];
}

class _PieChartPainter extends CustomPainter {
  final List<dynamic> options;
  final int totalVotes;
  final double progress;
  final Color bgColor;

  _PieChartPainter({
    required this.options,
    required this.totalVotes,
    required this.progress,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = 14.0;

    // Draw background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (totalVotes == 0) return;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -pi / 2;

    for (int i = 0; i < options.length; i++) {
      final count = _asInt(options[i]["vote_count"]);
      if (count == 0) continue;

      final sweepAngle = (count / totalVotes) * 2 * pi;

      // Each segment grows to its full length multiplied by progress
      // But to make them stick together, we need to handle startAngle logic or global rotation.
      // Let's sweep * progress.
      final animatedSweep = sweepAngle * progress;

      final paint = Paint()
        ..color = _getColor(i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, animatedSweep, false, paint);

      // Move start angle for next segment
      // If we want a "filling up" effect, startAngle stays, but that draws over.
      // We want them to appear sequentially or simultaneously.
      // Simultaneous growth:
      startAngle += sweepAngle;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
